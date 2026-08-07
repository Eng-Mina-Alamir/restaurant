import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../orders/domain/entities/order_entity.dart';
import '../../../orders/presentation/controllers/orders_controller.dart';
import '../../domain/entities/restaurant_table.dart';
import '../controllers/table_controller.dart';
import 'waiter_dashboard_page.dart';

/// Waiter table detail: shows table info, the linked active order (if any)
/// and floor actions (take order, reserve, clean/release).
class TableDetailPage extends ConsumerWidget {
  const TableDetailPage({super.key, required this.tableId});

  final String tableId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tables = ref.watch(tableControllerProvider);
    RestaurantTable? table;
    for (final t in tables) {
      if (t.id == tableId) table = t;
    }
    if (table == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppConstants.tableDetailTitle)),
        body: const EmptyState(
          message: AppConstants.tableNoOrder,
          icon: Icons.table_restaurant_outlined,
        ),
      );
    }

    OrderEntity? activeOrder;
    if (table.currentOrderId != null) {
      for (final o in ref.watch(ordersControllerProvider)) {
        if (o.id == table.currentOrderId) activeOrder = o;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${AppConstants.tableDetailTitle} — '
          '${AppConstants.seats} ${table.tableNumber}',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _TableInfoRow(table: table),
          const SizedBox(height: AppSpacing.lg),
          Text(
            AppConstants.tableActiveOrder,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (activeOrder == null)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Text(AppConstants.tableNoOrder),
              ),
            )
          else
            _ActiveOrderCard(order: activeOrder),
          const SizedBox(height: AppSpacing.lg),
          if (table.status != TableStatus.occupied)
            FilledButton.icon(
              onPressed: () => context.push('/waiter/order/$tableId'),
              icon: const Icon(Icons.add),
              label: const Text(AppConstants.tableActionTakeOrder),
            ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ref
                      .read(tableControllerProvider.notifier)
                      .release(tableId),
                  icon: const Icon(Icons.fullscreen_exit),
                  label: const Text(AppConstants.tableActionRelease),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ref
                      .read(tableControllerProvider.notifier)
                      .setReserved(tableId, reserved: true),
                  icon: const Icon(Icons.event_available),
                  label: const Text(AppConstants.tableActionReserve),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TableInfoRow extends StatelessWidget {
  const _TableInfoRow({required this.table});

  final RestaurantTable table;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(child: Text('${table.tableNumber}')),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${table.capacity} ${AppConstants.seats}',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      table.location,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  tableStatusLabel(table.status),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: tableStatusColor(table.status),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveOrderCard extends StatelessWidget {
  const _ActiveOrderCard({required this.order});

  final OrderEntity order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
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
                Text(order.status.labelAr),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final item in order.items)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('${item.quantity} × ${item.menuItem.name}'),
                    ),
                    Text(
                      Formatters.formatCurrency(item.itemTotal),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            const Divider(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppConstants.orderTotalLabel,
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  Formatters.formatCurrency(order.totalAmount),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (order.paymentMethod != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppConstants.paymentMethodLabel,
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    order.paymentMethod!.labelAr,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _orderNumber(OrderEntity order) =>
      '#${order.id.replaceAll(RegExp(r'[^0-9]'), '')}';
}
