import 'package:get/get.dart';

import '../model/cart_item_model.dart';
import '../model/deal_model.dart';
import '../util/log_service.dart';

/// App-wide cart. Lives for the whole session.
import '../model/reservation_model.dart';
import '../model/reservation_status.dart';
import '../../repository/order_repo.dart';
import '../../service/api_exception.dart';

class CartService extends GetxService {
  final OrderRepo orderRepo;

  CartService({
    required this.orderRepo,
  });

  final items = <CartItemModel>[].obs;

  int get itemCount => items.fold(
        0,
        (sum, item) => sum + item.quantity,
      );

  num get total => items.fold(
        0,
        (sum, item) => sum + item.lineTotal,
      );

  bool existsById(int dealId) {
    return items.any(
      (item) => item.deal.id == dealId,
    );
  }

  CartItemModel? findByDealId(int dealId) {
    return items.firstWhereOrNull(
      (item) => item.deal.id == dealId,
    );
  }

  Future<CartOperationResult> add(DealModel deal) async {
    final existing = findByDealId(deal.id);

    if (existing != null) {
      return increment(existing);
    }

    final item = CartItemModel(
      deal: deal,
      quantity: 1,
      reservation: ReservationModel(
        id: '${deal.id}-1',
        dealId: deal.id,
        quantity: 1,
        expiresAt: DateTime.now().add(
          const Duration(minutes: 5),
        ),
      ),
      reservationStatus: ReservationStatus.reserving,
    );

    // Optimistic cart update.
    items.add(item);

    LogService.log(
      'Added item ${deal.name} to cart.',
    );

    try {
      final reservation = await orderRepo.reserve(
        deal.id,
        quantity: 1,
      );

      item.reservation = reservation;
      item.reservationStatus = ReservationStatus.reserved;

      items.refresh();

      return CartOperationResult.success();
    } on ApiException catch (e) {
      LogService.error(
        'add to cart reservation failed',
        e,
      );

      items.remove(item);

      return CartOperationResult.failure(
        statusCode: e.statusCode,
        message: e.message,
      );
    } catch (e) {
      LogService.error(
        'add to cart reservation failed',
        e,
      );

      items.remove(item);

      return CartOperationResult.failure(
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<CartOperationResult> increment(
    CartItemModel item,
  ) async {
    return _changeQuantity(
      item,
      item.quantity + 1,
    );
  }

  Future<CartOperationResult> decrement(
    int dealId,
  ) async {
    final item = findByDealId(dealId);

    if (item == null) {
      return CartOperationResult.failure(
        message: 'Item is not in the cart.',
      );
    }

    if (item.quantity <= 1) {
      return remove(dealId);
    }

    return _changeQuantity(
      item,
      item.quantity - 1,
    );
  }

  Future<CartOperationResult> _changeQuantity(
    CartItemModel item,
    int newQuantity,
  ) async {
    if (newQuantity < 1) {
      return CartOperationResult.failure(
        message: 'Invalid quantity.',
      );
    }

    final oldQuantity = item.quantity;
    final oldReservation = item.reservation;

    // Optimistic quantity update.
    item.quantity = newQuantity;
    item.reservationStatus = ReservationStatus.reserving;

    items.refresh();

    try {
      // No adjustReservation API exists.
      // Release the old reservation first.
      if (oldReservation != null) {
        await orderRepo.releaseReservation(
          oldReservation.id,
        );
      }

      final reservation = await orderRepo.reserve(
        item.deal.id,
        quantity: newQuantity,
      );

      item.reservation = reservation;
      item.reservationStatus = ReservationStatus.reserved;

      items.refresh();

      return CartOperationResult.success();
    } on ApiException catch (e) {
      LogService.error(
        'quantity reservation failed',
        e,
      );

      item.quantity = oldQuantity;
      item.reservation = null;

      item.reservationStatus = e.statusCode == 409 ? ReservationStatus.timedOut : ReservationStatus.failed;

      items.refresh();

      return CartOperationResult.failure(
        statusCode: e.statusCode,
        message: e.message,
      );
    } catch (e) {
      LogService.error(
        'quantity reservation failed',
        e,
      );

      item.quantity = oldQuantity;
      item.reservation = null;
      item.reservationStatus = ReservationStatus.failed;

      items.refresh();

      return CartOperationResult.failure(
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<CartOperationResult> remove(
    int dealId,
  ) async {
    final item = findByDealId(dealId);

    if (item == null) {
      return CartOperationResult.failure(
        message: 'Item is not in the cart.',
      );
    }

    final reservation = item.reservation;

    // Optimistic removal.
    items.remove(item);

    if (reservation == null) {
      return CartOperationResult.success();
    }

    try {
      await orderRepo.releaseReservation(
        reservation.id,
      );

      return CartOperationResult.success();
    } catch (e) {
      LogService.error(
        'release reservation failed',
        e,
      );

      // We don't put the item back because removal
      // was already intentionally performed.
      return CartOperationResult.failure(
        message: 'Could not release reservation.',
      );
    }
  }

  Future<CartOperationResult> reserveAgain(
    CartItemModel item,
  ) async {
    if (item.reservationStatus == ReservationStatus.reserving) {
      return CartOperationResult.failure(
        message: 'Reservation is already being processed.',
      );
    }

    item.reservationStatus = ReservationStatus.reserving;
    item.reservation = null;

    items.refresh();

    try {
      final reservation = await orderRepo.reserve(
        item.deal.id,
        quantity: item.quantity,
      );

      item.reservation = reservation;
      item.reservationStatus = ReservationStatus.reserved;

      items.refresh();

      return CartOperationResult.success();
    } on ApiException catch (e) {
      LogService.error(
        'reserve again failed',
        e,
      );

      item.reservation = null;

      item.reservationStatus = e.statusCode == 409 ? ReservationStatus.timedOut : ReservationStatus.failed;

      items.refresh();

      return CartOperationResult.failure(
        statusCode: e.statusCode,
        message: e.message,
      );
    } catch (e) {
      LogService.error(
        'reserve again failed',
        e,
      );

      item.reservation = null;
      item.reservationStatus = ReservationStatus.failed;

      items.refresh();

      return CartOperationResult.failure(
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  bool checkReservations() {
    var changed = false;

    for (final item in items) {
      if (item.reservationStatus != ReservationStatus.reserved) {
        continue;
      }

      final reservation = item.reservation;

      if (reservation == null) {
        continue;
      }

      if (!reservation.expiresAt.isAfter(DateTime.now())) {
        item.reservation = null;
        item.reservationStatus = ReservationStatus.expired;

        changed = true;
      }
    }

    if (changed) {
      items.refresh();
    }

    return changed;
  }

  bool get canCheckout {
    if (items.isEmpty) {
      return false;
    }

    return items.every((item) {
      final reservation = item.reservation;

      return item.reservationStatus == ReservationStatus.reserved && reservation != null && reservation.expiresAt.isAfter(DateTime.now());
    });
  }

  Future<CheckoutResult> checkout() async {
    if (!canCheckout) {
      return CheckoutResult.failure(
        message: 'One or more reservations have expired.',
      );
    }

    try {
      final order = await orderRepo.checkout(
        items.toList(),
      );

      items.clear();

      return CheckoutResult.success(order);
    } on ApiException catch (e) {
      LogService.error(
        'checkout failed',
        e,
      );

      if (e.statusCode == 410) {
        markReservationsExpired();
      }

      return CheckoutResult.failure(
        statusCode: e.statusCode,
        message: e.message,
      );
    } catch (e) {
      LogService.error(
        'checkout failed',
        e,
      );

      return CheckoutResult.failure(
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  void markReservationsExpired() {
    for (final item in items) {
      item.reservation = null;
      item.reservationStatus = ReservationStatus.expired;
    }

    items.refresh();
  }

  void clear() {
    items.clear();
  }
}

class CartOperationResult {
  final bool success;
  final int? statusCode;
  final String? message;

  const CartOperationResult._({
    required this.success,
    this.statusCode,
    this.message,
  });

  factory CartOperationResult.success() {
    return const CartOperationResult._(
      success: true,
    );
  }

  factory CartOperationResult.failure({
    int? statusCode,
    String? message,
  }) {
    return CartOperationResult._(
      success: false,
      statusCode: statusCode,
      message: message,
    );
  }
}

class CheckoutResult {
  final bool success;
  final int? statusCode;
  final String? message;
  final dynamic order;

  const CheckoutResult._({
    required this.success,
    this.statusCode,
    this.message,
    this.order,
  });

  factory CheckoutResult.success(dynamic order) {
    return CheckoutResult._(
      success: true,
      order: order,
    );
  }

  factory CheckoutResult.failure({
    int? statusCode,
    String? message,
  }) {
    return CheckoutResult._(
      success: false,
      statusCode: statusCode,
      message: message,
    );
  }
}
