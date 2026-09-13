import 'package:flutter/material.dart';
import 'package:rescu/feature/home/widget/flash_deal_card.dart';
import 'package:rescu/model/pickup_window_model.dart';
import '../../../model/deal_model.dart';

/// Horizontal flash-sale rail.
///
/// NOTE: the countdown is currently a static "Ends soon" label — turning it
/// into a live per-deal countdown is one of the feature tasks in PROBLEM.md.
class FlashDealsSection extends StatelessWidget {
  final List<DealModel> deals;

  const FlashDealsSection({super.key, required this.deals});

  @override
  Widget build(BuildContext context) {
    final dealss = [
      DealModel(
          id: 0,
          name: 'Dummy',
          description: '',
          imageUrl: '',
          originalPrice: 100,
          price: 80,
          currencyCode: '',
          quantityLeft: 2,
          storeId: 2,
          storeName: '',
          storeAddress: '',
          lat: 2,
          lng: 2,
          rating: 2,
          tags: [],
          pickupWindow: PickupWindowModel(start: DateTime.now(), end: DateTime.now()),
          flashSaleEndsAt: DateTime.now().add(Duration(seconds: 10))),
      ...deals
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(Icons.bolt, color: Colors.red, size: 20),
              SizedBox(width: 4),
              Text('Flash sales', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: dealss.length,
            itemBuilder: (context, index) {
              final deal = dealss[index];
              return FlashDealCard(
                deal: deal,
              );
            },
          ),
        ),
      ],
    );
  }
}
