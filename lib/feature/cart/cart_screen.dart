import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rescu/model/cart_item_model.dart';
import 'package:rescu/model/reservation_status.dart';
import '../shared_widget/the_network_image.dart';
import 'cart_controller.dart';

class CartScreen extends GetView<CartController> {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = controller.cartService;
    return Scaffold(
        appBar: AppBar(title: const Text('My bag')),
        body: Obx(() {
          if (cart.items.isEmpty) {
            return const Center(child: Text('Your bag is empty'));
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: cart.items.length,
            itemBuilder: (context, index) {
              final item = cart.items[index];
              return _CartItemCard(
                item: item,
                controller: controller,
              );
            },
          );
        }),
        bottomNavigationBar: Obx(() {
          if (cart.items.isEmpty) {
            return const SizedBox.shrink();
          }

          final canCheckout = controller.canCheckout;
          final isCheckingOut = controller.isCheckingOut.value;

          return Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            color: Colors.white,
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(fontSize: 13),
                    ),
                    Text(
                      '฿${cart.total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: FilledButton(
                    onPressed: isCheckingOut || !canCheckout ? null : controller.checkout,
                    child: isCheckingOut
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            canCheckout ? 'Checkout' : 'Resolve reservations',
                          ),
                  ),
                ),
              ],
            ),
          );
        }));
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItemModel item;
  final CartController controller;

  const _CartItemCard({
    required this.item,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ),
      color: Colors.white,
      elevation: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TheNetworkImage(
              url: item.deal.imageUrl,
              width: 64,
              height: 64,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.deal.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          item.deal.storeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '฿${item.deal.price.toStringAsFixed(0)} each',
                        ),
                        _ReservationStatus(
                          item: item,
                          controller: controller,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _QuantityControls(
                        item: item,
                        controller: controller,
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _ReservationStatus extends StatelessWidget {
  final CartItemModel item;
  final CartController controller;

  const _ReservationStatus({
    required this.item,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    switch (item.reservationStatus) {
      case ReservationStatus.none:
        return const SizedBox.shrink();

      case ReservationStatus.reserving:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 6),
            Text(
              'Reserving...',
              style: TextStyle(fontSize: 12),
            ),
          ],
        );

      case ReservationStatus.reserved:
        return _ReservationCountdown(
          item: item,
          controller: controller,
        );

      case ReservationStatus.expired:
        return _ReservationProblem(
          message: 'Reservation expired',
          onReserveAgain: () => controller.reserveAgain(item),
          onRemove: () => controller.remove(item.deal.id),
        );

      case ReservationStatus.timedOut:
        return _ReservationProblem(
          message: 'Reservation timed out',
          onReserveAgain: () => controller.reserveAgain(item),
          onRemove: () => controller.remove(item.deal.id),
        );

      case ReservationStatus.failed:
        return _ReservationProblem(
          message: 'Could not reserve this item',
          onReserveAgain: () => controller.reserveAgain(item),
          onRemove: () => controller.remove(item.deal.id),
        );
    }
  }
}

class _ReservationCountdown extends StatelessWidget {
  final CartItemModel item;
  final CartController controller;

  const _ReservationCountdown({
    required this.item,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Make this widget rebuild every second.
      controller.reservationTick.value;

      final expiresAt = item.reservation?.expiresAt;

      if (expiresAt == null) {
        return const Text(
          'Reserved',
          style: TextStyle(fontSize: 12),
        );
      }

      final remaining = expiresAt.difference(DateTime.now());

      if (remaining <= Duration.zero) {
        return const Text(
          'Reservation expired',
          style: TextStyle(fontSize: 12),
        );
      }

      return Text(
        'Reserved • ${_formatRemaining(remaining)}',
        style: const TextStyle(
          fontSize: 12,
        ),
      );
    });
  }

  String _formatRemaining(Duration remaining) {
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds.remainder(60);

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}

class _ReservationProblem extends StatelessWidget {
  final String message;
  final VoidCallback onReserveAgain;
  final VoidCallback onRemove;

  const _ReservationProblem({
    required this.message,
    required this.onReserveAgain,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 16,
              color: Colors.orange.shade700,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            TextButton.icon(
              onPressed: onReserveAgain,
              icon: const Icon(
                Icons.refresh,
                size: 16,
              ),
              label: const Text('Reserve again'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: onRemove,
              icon: const Icon(
                Icons.delete_outline,
                size: 16,
              ),
              label: const Text('Remove'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuantityControls extends StatelessWidget {
  final CartItemModel item;
  final CartController controller;

  const _QuantityControls({
    required this.item,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isReserving = item.reservationStatus == ReservationStatus.reserving;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(
            Icons.remove_circle_outline,
          ),
          onPressed: isReserving
              ? null
              : () => controller.decrement(
                    item.deal.id,
                  ),
        ),
        Text(
          '${item.quantity}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(
            Icons.add_circle_outline,
          ),
          onPressed: isReserving ? null : () => controller.increment(item),
        ),
      ],
    );
  }
}
