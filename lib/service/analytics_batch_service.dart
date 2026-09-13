import 'dart:async';

import 'package:get/get_rx/src/rx_workers/rx_workers.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_disposable.dart';
import 'package:rescu/service/analytics_service.dart';
import 'package:rescu/service/fake_api_service.dart';
import 'package:rescu/util/log_service.dart';

class AnalyticsBatchService extends GetxService {
  final AnalyticsService analytics;
  final FakeApiService api;

  AnalyticsBatchService({
    required this.analytics,
    required this.api,
  });

  final List<AnalyticsEvent> _pendingEvents = [];

  Timer? _flushTimer;
  Worker? _analyticsWorker;
  bool _isFlushing = false;

  @override
  void onInit() {
    super.onInit();

    _analyticsWorker = ever<List<AnalyticsEvent>>(
      analytics.events,
      (_) => _onAnalyticsEvent(),
    );
  }

  void _onAnalyticsEvent() {
    final event = analytics.events.last;

    _pendingEvents.add(event);

    // Start the 15-second window from the first
    // unsent event only.
    if (_pendingEvents.length == 1) {
      _startFlushTimer();
    }

    // Flush immediately at 10 events.
    if (_pendingEvents.length >= 10) {
      unawaited(flush());
    }
  }

  void _startFlushTimer() {
    _flushTimer?.cancel();

    _flushTimer = Timer(
      const Duration(seconds: 15),
      () => unawaited(flush()),
    );
  }

  Future<void> flush() async {
    if (_isFlushing || _pendingEvents.isEmpty) {
      return;
    }

    _isFlushing = true;

    _flushTimer?.cancel();
    _flushTimer = null;

    final batch = List<AnalyticsEvent>.from(
      _pendingEvents,
    );

    _pendingEvents.clear();

    try {
      await api.sendAnalyticsBatch(
        batch.map((event) => event.toJson()).toList(),
      );
    } catch (e) {
      // Put failed events back so they aren't lost.
      _pendingEvents.insertAll(0, batch);

      if (_pendingEvents.isNotEmpty) {
        _startFlushTimer();
      }

      LogService.error(
        'analytics batch failed',
        e,
      );
    } finally {
      _isFlushing = false;

      // Events could have arrived while the request
      // was running.
      if (_pendingEvents.length >= 10) {
        unawaited(flush());
      }
    }
  }

  @override
  void onClose() {
    _flushTimer?.cancel();
    _analyticsWorker?.dispose();

    super.onClose();
  }
}
