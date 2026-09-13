import 'dart:async';

import 'package:get/get.dart';

import '../../../model/deal_model.dart';

class FlashDealCardController extends GetxController {
  final DealModel deal;

  FlashDealCardController({required this.deal});

  final countdown = '--:--'.obs;

  Timer? _timer;

  @override
  void onInit() {
    super.onInit();

    _updateCountdown();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateCountdown(),
    );
  }

  void _updateCountdown() {
    final endsAt = deal.flashSaleEndsAt;

    if (endsAt == null) {
      countdown.value = '--:--';
      return;
    }

    final remaining = endsAt.difference(DateTime.now());

    if (remaining <= Duration.zero) {
      countdown.value = '00:00';
      _timer?.cancel();
      return;
    }

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

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
