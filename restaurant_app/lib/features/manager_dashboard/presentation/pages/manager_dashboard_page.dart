import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/constants.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../orders/presentation/controllers/orders_controller.dart';
import '../controllers/metrics_controller.dart';

/// Manager / admin dashboard: live sales metrics and top-selling items.
class ManagerDashboardPage extends ConsumerWidget {
  const ManagerDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(metricsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.managerTitle)),
      body: metrics.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (data) => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              AppConstants.metricsOverview,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: AppConstants.metricsSalesTitle,
                    value: Formatters.formatCurrency(data.totalSales),
                    icon: Icons.payments_outlined,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _MetricCard(
                    title: AppConstants.metricsOrdersTitle,
                    value: '${data.totalOrders}',
                    icon: Icons.receipt_long_outlined,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: AppConstants.metricsAvgOrderTitle,
                    value: Formatters.formatCurrency(data.averageOrderValue),
                    icon: Icons.percent_outlined,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _MetricCard(
                    title: AppConstants.metricsActiveTitle,
                    value: _activeOrders(ref),
                    icon: Icons.pending_actions_outlined,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              AppConstants.metricsItemsSold,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (data.itemsSold.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Text(AppConstants.metricsNoData),
                ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      for (final entry
                          in data.itemsSold.entries.toList()
                            ..sort((a, b) => b.value.compareTo(a.value)))
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xs,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(entry.key)),
                              Text(
                                '${entry.value}',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _activeOrders(WidgetRef ref) {
    final orders = ref.watch(ordersControllerProvider);
    final active = orders
        .where(
          (o) =>
              !o.status.toString().contains('completed') &&
              !o.status.toString().contains('cancelled'),
        )
        .length;
    return '$active';
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
