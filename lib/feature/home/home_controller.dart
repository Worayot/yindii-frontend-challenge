import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../model/deal_model.dart';
import '../../repository/deal_repo.dart';
import '../../util/log_service.dart';

class HomeController extends GetxController {
  final DealRepo dealRepo;

  HomeController({required this.dealRepo});

  final deals = <DealModel>[].obs;
  final flashDeals = <DealModel>[].obs;
  final isLoading = true.obs;
  final todayOnly = false.obs;
  final scrollOffset = 0.0.obs;

  final scrollController = ScrollController();
  final refreshController = RefreshController();

  int _page = 1;
  int _totalPages = 1;
  bool _isFetchingMore = false;
  int _requestGeneration = 0;

  bool get hasMore => _page < _totalPages;

  List<DealModel> get visibleDeals => todayOnly.value ? deals.where((d) => d.pickupWindow.isToday).toList() : deals.toList();

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    _initialLoad();
  }

  void _onScroll() {
    scrollOffset.value = scrollController.offset;
  }

  Future<void> _initialLoad() async {
    isLoading.value = true;
    try {
      await Future.wait([refreshDeals(), _loadFlashDeals()]);
    } catch (e) {
      LogService.error('initial load failed', e);
    }
    isLoading.value = false;
  }

  Future<void> _loadFlashDeals() async {
    flashDeals.assignAll(await dealRepo.fetchFlashDeals());
  }

  Future<void> refreshDeals() async {
    final generation = ++_requestGeneration;

    try {
      final res = await dealRepo.fetchDeals(page: 1);

      if (generation != _requestGeneration) return;

      _page = 1;
      _totalPages = res.totalPages;
      deals.assignAll(res.items);

      refreshController.resetNoData();
    } catch (e) {
      LogService.error('refreshDeals failed', e);
    } finally {
      refreshController.refreshCompleted();
    }
  }

  Future<void> loadMore() async {
    if (_isFetchingMore || !hasMore) {
      if (!hasMore) {
        refreshController.loadNoData();
      }
      return;
    }

    _isFetchingMore = true;

    final nextPage = _page + 1;
    final generation = _requestGeneration;

    try {
      final res = await dealRepo.fetchDeals(page: nextPage);

      if (generation != _requestGeneration) return;

      _page = nextPage;
      _totalPages = res.totalPages;
      deals.addAll(res.items);
    } catch (e) {
      LogService.error('loadMore failed', e);
    } finally {
      _isFetchingMore = false;

      if (generation == _requestGeneration) {
        refreshController.loadComplete();
      }
    }
  }

  void scrollToTop() {
    scrollController.animateTo(0, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
  }

  @override
  void onClose() {
    scrollController.dispose();
    refreshController.dispose();
    super.onClose();
  }
}
