import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:rescu/app_config.dart';
import 'package:rescu/feature/shared_widget/the_network_image.dart';
import 'package:rescu/model/deal_model.dart';
import 'package:rescu/routes/routes.dart';

import 'flash_deal_card_controller.dart';

class FlashDealCard extends StatefulWidget {
  final DealModel deal;

  const FlashDealCard({
    super.key,
    required this.deal,
  });

  @override
  State<FlashDealCard> createState() => _FlashDealCardState();
}

class _FlashDealCardState extends State<FlashDealCard> {
  late final String _tag;

  late final FlashDealCardController controller;

  @override
  void initState() {
    super.initState();

    _tag = 'flash-deal-${widget.deal.id}';

    controller = Get.put(
      FlashDealCardController(deal: widget.deal),
      tag: _tag,
    );
  }

  @override
  void dispose() {
    Get.delete<FlashDealCardController>(tag: _tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deal = widget.deal;

    return SizedBox(
      width: 200,
      child: Card(
        color: Colors.white,
        elevation: 0.5,
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: InkWell(
          onTap: () => Get.toNamed(
            Routes.dealRoute(
              deal.id,
              source: 'flash_rail',
            ),
            arguments: deal,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TheNetworkImage(
                url: deal.imageUrl,
                height: 90,
                width: double.infinity,
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deal.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      deal.storeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '฿${deal.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppConfig.primaryGreen,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Obx(
                            () => Text(
                              controller.countdown.value,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
