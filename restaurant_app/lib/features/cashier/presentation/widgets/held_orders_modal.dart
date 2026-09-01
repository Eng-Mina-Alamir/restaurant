import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../domain/entities/held_order_entity.dart';
import '../controllers/held_orders_controller.dart';

/// Modal dialog displaying and recalling parked / held orders at the cashier terminal.
class HeldOrdersModal extends ConsumerWidget {
  const HeldOrdersModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.xl)),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540, maxHeight: 600),
          child: const HeldOrdersModal(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final heldOrders = ref.watch(heldOrdersControllerProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.pause_circle_filled_rounded,
                  color: Color(0xFFF59E0B),
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'الطلبات المعلقة (Held / Parked Orders)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${heldOrders.length} طلبات معلقة بانتظار الاستدعاء والمحاسبة',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),

          // Park Current Active Cart Button
          _ParkCurrentCartBar(ref: ref),
          const SizedBox(height: AppSpacing.sm),

          // Held Orders List
          Expanded(
            child: heldOrders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const Text(
                          'لا توجد أي طلبات معلقة حالياً',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'يمكنك تعليق أي طلب نشط لخدمة الزبون التالي فوراً',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: heldOrders.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (ctx, index) {
                      final order = heldOrders[index];
                      return _HeldOrderCard(
                        order: order,
                        onRecall: () {
                          // 1. Recall items from held orders
                          final recalled = ref
                              .read(heldOrdersControllerProvider.notifier)
                              .recallOrder(order.id);

                          if (recalled != null) {
                            // 2. Load recalled items into active cart
                            final cartNotifier =
                                ref.read(cartControllerProvider.notifier);
                            cartNotifier.clear();
                            for (final item in recalled.items) {
                              cartNotifier.addItem(item);
                            }

                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'تم استدعاء "${order.label}" للسلة بنجاح ✅',
                                ),
                                backgroundColor: const Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        onDiscard: () {
                          ref
                              .read(heldOrdersControllerProvider.notifier)
                              .discardHeldOrder(order.id);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ParkCurrentCartBar extends StatelessWidget {
  const _ParkCurrentCartBar({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartControllerProvider);
    final hasItems = cartItems.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 20,
            color: hasItems ? const Color(0xFFF59E0B) : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasItems
                  ? 'السلة الحالية تحتوي على ${cartItems.length} أصناف'
                  : 'السلة الحالية فارغة',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          FilledButton.tonalIcon(
            onPressed: hasItems
                ? () {
                    final held = ref
                        .read(heldOrdersControllerProvider.notifier)
                        .holdOrder(cartItems: List<CartItem>.from(cartItems));

                    if (held != null) {
                      ref.read(cartControllerProvider.notifier).clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'تم تعليق الطلب (${held.label}) وإفراغ السلة للزبون التالي ✅',
                          ),
                          backgroundColor: const Color(0xFFF59E0B),
                        ),
                      );
                    }
                  }
                : null,
            icon: const Icon(Icons.pause_circle_outline, size: 16),
            label: const Text('تعليق السلة الحالية'),
          ),
        ],
      ),
    );
  }
}

class _HeldOrderCard extends StatelessWidget {
  const _HeldOrderCard({
    required this.order,
    required this.onRecall,
    required this.onDiscard,
  });

  final HeldOrderEntity order;
  final VoidCallback onRecall;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerLow : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      order.label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    Formatters.formatTime(order.parkedAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Text(
                Formatters.formatCurrency(order.totalAmount),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Items summary
          Text(
            order.items
                .map((i) => '${i.menuItem.name} × ${i.quantity}')
                .join(' • '),
            style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onDiscard,
                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                label: const Text('إلغاء', style: TextStyle(color: Colors.red, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                onPressed: onRecall,
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('استدعاء للسلة', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
