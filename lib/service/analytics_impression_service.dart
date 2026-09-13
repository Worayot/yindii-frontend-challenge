import 'package:get/get_state_manager/src/rx_flutter/rx_disposable.dart';
import 'package:rescu/service/analytics_service.dart';

class AnalyticsImpressionService extends GetxService {
  final AnalyticsService analytics;

  AnalyticsImpressionService({
    required this.analytics,
  });

  final Set<int> _impressedDealIds = {};

  bool alreadyImpressed(int dealId) {
    return _impressedDealIds.contains(dealId);
  }

  void recordImpression({
    required int dealId,
    required String source,
    required int position,
  }) {
    if (_impressedDealIds.contains(dealId)) {
      return;
    }

    _impressedDealIds.add(dealId);

    analytics.logEvent(
      'deal_impression',
      {
        'deal_id': dealId,
        'source': source,
        'position': position,
      },
    );
  }
}
