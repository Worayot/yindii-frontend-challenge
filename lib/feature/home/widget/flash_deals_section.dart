import 'package:flutter/material.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:rescu/feature/home/widget/flash_deal_card.dart';
import '../../../model/deal_model.dart';

/// Horizontal flash-sale rail.
///
/// NOTE: the countdown is currently a static "Ends soon" label — turning it
/// into a live per-deal countdown is one of the feature tasks in PROBLEM.md.
class FlashDealsSection extends StatelessWidget {
  final RxList<DealModel> deals;

  const FlashDealsSection({
    super.key,
    required this.deals,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final activeDeals = deals.toList();

      if (activeDeals.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(
                  Icons.bolt,
                  color: Colors.red,
                  size: 20,
                ),
                SizedBox(width: 4),
                Text(
                  'Flash sales',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 190,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: activeDeals.length,
              itemBuilder: (context, index) {
                return FlashDealCard(
                  deal: activeDeals[index],
                );
              },
            ),
          ),
        ],
      );
    });
  }
}
