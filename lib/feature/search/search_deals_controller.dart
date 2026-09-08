import 'package:get/get.dart';

import '../../model/deal_model.dart';
import '../../repository/deal_repo.dart';
import '../../util/log_service.dart';

class SearchDealsController extends GetxController {
  final DealRepo dealRepo;

  SearchDealsController({required this.dealRepo});

  final query = ''.obs;

  final results = <DealModel>[].obs;
  final isLoading = false.obs;
  final hasSearched = false.obs;

  @override
  void onInit() {
    super.onInit();

    debounce(
      query,
      (_) => _search(query.value),
      time: const Duration(milliseconds: 300),
    );
  }

  void onQueryChanged(String value) {
    query.value = value;
  }

  Future<void> _search(String query) async {
    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      results.clear();
      hasSearched.value = false;
      return;
    }

    isLoading.value = true;
    hasSearched.value = true;

    try {
      final found = await dealRepo.search(trimmedQuery);
      results.assignAll(found);
    } catch (e) {
      LogService.error('search failed', e);
    } finally {
      isLoading.value = false;
    }
  }
}
