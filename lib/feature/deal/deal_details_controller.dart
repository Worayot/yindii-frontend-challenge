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

  @override
  void onInit() {
    super.onInit();

    final argument = Get.arguments;

    if (argument is DealModel) {
      // Home navigation: model already exists.
      deal.value = argument;
      _onDealLoaded(argument);
    } else {
      // Deep link: only ID is available.
      _loadDealFromDeepLink();
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

    isLoading.value = false;
  }

  @override
  void onClose() {
    _cartWorker?.dispose();
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
