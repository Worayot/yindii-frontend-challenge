import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../model/deal_model.dart';
import '../../repository/deal_repo.dart';
import '../../service/analytics_service.dart';
import '../../service/cart_service.dart';
import '../../util/log_service.dart';

class DealDetailsController extends GetxController {
  final DealRepo dealRepo;
  final CartService cartService;
  final AnalyticsService analytics;

  DealDetailsController({
    required this.dealRepo,
    required this.cartService,
    required this.analytics,
  });

  final deal = Rxn<DealModel>();
  final isLoading = true.obs;
  Worker? _cartWorker;

  final _quantityLeft = RxnInt();
  int? get quantityLeft => _quantityLeft.value;

  final countdown = '--:--'.obs;
  Timer? _timer;

  final flashSaleExpired = false.obs;

  bool get isFlashSale => deal.value?.flashSaleEndsAt != null;
  bool get isFlashSaleExpired => isFlashSale && flashSaleExpired.value;
  bool get canAddToBag => !isFlashSaleExpired && (_quantityLeft.value ?? 0) > 0;

  @override
  void onInit() {
    super.onInit();

    final argument = Get.arguments;

    if (argument is DealModel) {
      deal.value = argument;
      _onDealLoaded(argument);
    } else {
      _loadDealFromDeepLink();
    }
  }

  void _updateCountdown() {
    final currentDeal = deal.value;
    final endsAt = currentDeal?.flashSaleEndsAt;

    if (currentDeal == null || endsAt == null) {
      flashSaleExpired.value = false;
      countdown.value = '--:--';
      return;
    }

    final remaining = endsAt.difference(DateTime.now());

    if (remaining <= Duration.zero) {
      flashSaleExpired.value = true;
      countdown.value = '00:00';
      _timer?.cancel();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (isClosed) return;

        if (!cartService.existById(currentDeal.id)) return;

        cartService.remove(currentDeal.id);

        Get.snackbar(
          'Flash sale ended',
          '${currentDeal.name} has been removed from your bag.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      });

      return;
    }

    flashSaleExpired.value = false;

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);

    if (hours > 0) {
      countdown.value = '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    } else {
      countdown.value = '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _loadDealFromDeepLink() async {
    try {
      final dealId = int.parse(Get.parameters['id']!);

      final fetchedDeal = await dealRepo.fetchById(dealId);

      deal.value = fetchedDeal;
      _onDealLoaded(fetchedDeal);
    } catch (e) {
      LogService.error('failed to load deal details', e);
    } finally {
      isLoading.value = false;
    }
  }

  void _onDealLoaded(DealModel loadedDeal) {
    _quantityLeft.value = loadedDeal.quantityLeft;

    analytics.logEvent('deal_details_view', {
      'deal_id': loadedDeal.id,
      'source': Get.parameters['source'] ?? 'unknown',
    });

    _cartWorker = ever(
      cartService.items,
      (_) => _recheckAvailability(),
    );

    _startCountdown(loadedDeal);

    isLoading.value = false;
  }

  void _startCountdown(DealModel deal) {
    final endsAt = deal.flashSaleEndsAt;

    if (endsAt == null) {
      flashSaleExpired.value = false;
      countdown.value = '--:--';
      return;
    }

    _updateCountdown();

    if (flashSaleExpired.value) {
      return;
    }

    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateCountdown(),
    );
  }

  @override
  void onClose() {
    _cartWorker?.dispose();
    _timer?.cancel();
    super.onClose();
  }

  Future<void> _recheckAvailability() async {
    final currentDeal = deal.value;

    if (currentDeal == null) return;

    LogService.log(
      're-checking availability for deal ${currentDeal.id}',
    );

    final fresh = await dealRepo.fetchById(currentDeal.id);

    _quantityLeft.value = fresh.quantityLeft;
  }

  void addToCart() {
    final currentDeal = deal.value;

    if (currentDeal == null) return;

    cartService.add(currentDeal);

    Get.snackbar(
      'Added to bag',
      '${currentDeal.name} — pick up ${currentDeal.pickupWindow.label}',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }
}
