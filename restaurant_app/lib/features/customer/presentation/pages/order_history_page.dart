import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/constants.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../../orders/domain/entities/order_entity.dart';
import '../../../orders/presentation/controllers/orders_controller.dart';

/// Customer order history: lists past orders and lets the user re-order (add
/// the full contents of a past order back to the cart).
class OrderHistoryPage extends ConsumerWidget {
  const OrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.orderHistoryTitle)),
      body: orders.isEmpty
          ? const Center(child: Text(AppConstants.emptyOrders))
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: orders.length,
              itemBuilder: (context, index) => _OrderHistoryCard(
                order: orders[index],
                onReorder: () => _reorder(ref, orders[index], context),
              ),
            ),
    );
  }

  void _reorder(WidgetRef ref, OrderEntity order, BuildContext context) {
    final cart = ref.read(cartControllerProvider.notifier);
    for (final item in order.items) {
      cart.addItem(
        CartItem(
          menuItem: item.menuItem,
          quantity: item.quantity,
          selectedModifiers: item.selectedModifiers,
          specialNotes: item.specialNotes,
        ),
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '${AppConstants.reorderAction} — ${AppConstants.checkout}',
        ),
      ),
    );
  }
}

class _OrderHistoryCard extends StatelessWidget {
  const _OrderHistoryCard({required this.order, required this.onReorder});

  final OrderEntity order;
  final VoidCallback onReorder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _orderNumber(order),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  order.status.labelAr,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            if (order.paymentMethod != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${AppConstants.paymentMethodDisplayLabel}: '
                '${order.paymentMethod!.labelAr}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(
              order.items
                  .map((i) => '${i.quantity} × ${i.menuItem.name}')
                  .join('، '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Formatters.formatDate(order.createdAt),
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  Formatters.formatCurrency(order.totalAmount),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: OutlinedButton.icon(
                onPressed: onReorder,
                icon: const Icon(Icons.replay),
                label: const Text(AppConstants.reorderAction),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _orderNumber(OrderEntity order) {
    final digits = order.id.replaceAll(RegExp(r'[^0-9]'), '');
    return '#$digits';
  }
}
