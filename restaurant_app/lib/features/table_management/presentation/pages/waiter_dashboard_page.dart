import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/logout_action_button.dart';
import '../../../orders/domain/entities/order_entity.dart';
import '../../../orders/presentation/controllers/orders_controller.dart';
import '../controllers/table_controller.dart';
import 'waiter_table_card.dart';

/// Waiter / captain dashboard: a grid of restaurant tables with status-aware
/// actions (take order, release, clean, reserve).
class WaiterDashboardPage extends ConsumerWidget {
  const WaiterDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tables = ref.watch(tableControllerProvider);
    final orders = ref.watch(ordersControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.tablesTitle),
        actions: const [LogoutActionButton()],
      ),
      body: tables.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    0,
                  ),
                  child: _OrdersSummary(orders: orders),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.15,
                          crossAxisSpacing: AppSpacing.md,
                          mainAxisSpacing: AppSpacing.md,
                        ),
                    itemCount: tables.length,
                    itemBuilder: (context, index) {
                      final table = tables[index];
                      return WaiterTableCard(
                        table: table,
                        onTap: () {
                          context.push('/waiter/table/${table.id}');
                        },
                        onTakeOrder: () {
                          context.push('/waiter/order/${table.id}');
                        },
                        onRelease: () => ref
                            .read(tableControllerProvider.notifier)
                            .release(table.id),
                        onReserve: () => ref
                            .read(tableControllerProvider.notifier)
                            .setReserved(table.id, reserved: true),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

/// Compact live counters of active order statuses for the waiter.
class _OrdersSummary extends StatelessWidget {
  const _OrdersSummary({required this.orders});

  final List<OrderEntity> orders;

  @override
  Widget build(BuildContext context) {
    final pending = orders.where((o) => o.status == OrderStatus.pending).length;
    final preparing = orders
        .where((o) => o.status == OrderStatus.preparing)
        .length;
    final ready = orders.where((o) => o.status == OrderStatus.ready).length;
    final total = pending + preparing + ready;

    if (total == 0) return const SizedBox.shrink();

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppConstants.waiterOrdersSummary,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  _CountChip(
                    label: AppConstants.waiterPendingCount,
                    count: pending,
                    color: Colors.orange,
                  ),
                  _CountChip(
                    label: AppConstants.waiterPreparingCount,
                    count: preparing,
                    color: Colors.blue,
                  ),
                  _CountChip(
                    label: AppConstants.waiterReadyCount,
                    count: ready,
                    color: Colors.green,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        '$label: $count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

/// Color used to signal the table status in the grid.
Color tableStatusColor(TableStatus status) {
  switch (status) {
    case TableStatus.available:
      return Colors.green;
    case TableStatus.occupied:
      return Colors.deepOrange;
    case TableStatus.reserved:
      return Colors.blue;
    case TableStatus.needsCleaning:
      return Colors.brown;
  }
}
