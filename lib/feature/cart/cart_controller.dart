import 'dart:async';

import 'package:get/get.dart';

import '../../model/cart_item_model.dart';
import '../../model/deal_model.dart';
import '../../service/cart_service.dart';

class CartController extends GetxController {
  final CartService cartService;

  CartController({
    required this.cartService,
  });

  final isCheckingOut = false.obs;

  /// Changes every second so only reservation
  /// countdown widgets need to rebuild.
  final reservationTick = 0.obs;

  Timer? _reservationTimer;

  @override
  void onInit() {
    super.onInit();

    _startReservationTimer();
  }

  Future<void> add(DealModel deal) async {
    final result = await cartService.add(deal);

    if (result.success) {
      Get.snackbar(
        'Added to bag',
        '${deal.name} was added to your bag.',
        snackPosition: SnackPosition.BOTTOM,
      );

      return;
    }

    _showAddError(result);
  }

  Future<void> increment(CartItemModel item) async {
    final result = await cartService.increment(item);

    if (!result.success) {
      _showCartError(result);
    }
  }

  Future<void> decrement(int dealId) async {
    final result = await cartService.decrement(dealId);

    if (!result.success) {
      _showCartError(result);
    }
  }

  Future<void> remove(int dealId) async {
    final result = await cartService.remove(dealId);

    if (!result.success) {
      _showCartError(result);
    }
  }

  Future<void> reserveAgain(
    CartItemModel item,
  ) async {
    final result = await cartService.reserveAgain(item);

    if (!result.success) {
      _showCartError(result);
    }
  }

  void _startReservationTimer() {
    _reservationTimer?.cancel();

    _reservationTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        cartService.checkReservations();

        // UI-only state.
        // Countdown widgets listen to this.
        reservationTick.value++;
      },
    );
  }

  bool get canCheckout {
    return cartService.canCheckout;
  }

  Future<void> checkout() async {
    if (isCheckingOut.value) {
      return;
    }

    if (!cartService.canCheckout) {
      Get.snackbar(
        'Cannot checkout',
        'One or more reservations have expired.',
        snackPosition: SnackPosition.BOTTOM,
      );

      return;
    }

    isCheckingOut.value = true;

    try {
      final result = await cartService.checkout();

      if (result.success) {
        Get.snackbar(
          'Order confirmed',
          'Order #${result.order.id} — pick up soon!',
          snackPosition: SnackPosition.BOTTOM,
        );

        return;
      }

      if (result.statusCode == 410) {
        Get.snackbar(
          'Reservation expired',
          'Your reservation expired. Please reserve the item again.',
          snackPosition: SnackPosition.BOTTOM,
        );

        return;
      }

      Get.snackbar(
        'Checkout failed',
        result.message ?? 'Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isCheckingOut.value = false;
    }
  }

  bool containsDeal(int dealId) {
    return cartService.existsById(dealId);
  }

  void _showAddError(CartOperationResult result) {
    Get.snackbar(
      'Could not add to bag',
      result.statusCode == 409 ? 'Someone else got this deal first. Please try again.' : result.message ?? 'Could not reserve this deal. Please try again.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _showCartError(CartOperationResult result) {
    Get.snackbar(
      'Cart error',
      result.message ?? 'Something went wrong. Please try again.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  void onClose() {
    _reservationTimer?.cancel();
    super.onClose();
  }
}
