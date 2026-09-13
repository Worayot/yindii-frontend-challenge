import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:rescu/feature/home/home_controller.dart';
import 'package:rescu/model/deal_model.dart';

class FlashDealCountdown extends StatelessWidget {
  final DealModel deal;

  const FlashDealCountdown({
    super.key,
    required this.deal,
  });

  @override
  Widget build(BuildContext context) {
    final homeController = Get.find<HomeController>();

    return Obx(() {
      // Listen to the single shared timer.
      homeController.flashDealTick.value;

      return Text(
        _formatRemaining(deal.flashSaleEndsAt),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.red.shade700,
        ),
      );
    });
  }

  String _formatRemaining(DateTime? endsAt) {
    if (endsAt == null) {
      return '--:--';
    }

    final remaining = endsAt.difference(DateTime.now());

    if (remaining <= Duration.zero) {
      return '00:00';
    }

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}
