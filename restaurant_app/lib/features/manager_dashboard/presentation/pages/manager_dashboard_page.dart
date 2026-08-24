import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/animations/animated_press_card.dart';
import '../../../../shared/widgets/logout_action_button.dart';
import '../../../../shared/widgets/responsive_layout.dart';
import '../../../orders/domain/entities/order_entity.dart';
import '../../../orders/presentation/controllers/orders_controller.dart';
import '../controllers/alerts_controller.dart';
import '../controllers/dispatch_controller.dart';
import '../controllers/metrics_controller.dart';
import '../widgets/peak_hours_chart.dart';
import '../widgets/sales_line_chart.dart';
import '../widgets/top_items_bar_chart.dart';

/// Manager / admin dashboard: live sales metrics and top-selling items.
class ManagerDashboardPage extends ConsumerWidget {
  const ManagerDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(metricsControllerProvider);
    final unreadAlerts = ref.watch(unreadAlertsCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.managerTitle),
        actions: [
          IconButton(
            tooltip: 'مركز التنبيهات',
            icon: Badge(
              isLabelVisible: unreadAlerts > 0,
              label: Text('$unreadAlerts'),
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () => context.push('/manager/alerts'),
          ),
          IconButton(
            tooltip: AppConstants.allOrdersTitle,
            icon: const Icon(Icons.receipt_long),
            onPressed: () => context.push('/manager/orders'),
          ),
          const LogoutActionButton(),
        ],
      ),
      body: metrics.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (data) => ResponsiveBuilder(
          builder: (context, screenType, constraints) {
            final isWide = screenType != ScreenType.mobile;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    Text(
                      AppConstants.metricsOverview,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (isWide)
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
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _MetricCard(
                              title: AppConstants.metricsAvgOrderTitle,
                              value: Formatters.formatCurrency(
                                data.averageOrderValue,
                              ),
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
                      )
                    else ...[
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
                              value: Formatters.formatCurrency(
                                data.averageOrderValue,
                              ),
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
                    ],
                    const SizedBox(height: AppSpacing.lg),

                    // ── Dispatch health ──────────────────────────────────────
                    const _DispatchHealthCard(),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      AppConstants.metricsOrdersByStatus,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _StatusBreakdown(
                      orders: ref.watch(ordersControllerProvider),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Quick Actions grid ──────────────────────────────────────────
                    Text(
                      'الإجراءات السريعة',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: isWide ? 6 : 3,
                      crossAxisSpacing: AppSpacing.sm,
                      mainAxisSpacing: AppSpacing.sm,
                      childAspectRatio: isWide ? 1.2 : 1.0,
                      children: [
                        _QuickAction(
                          icon: Icons.restaurant_menu_rounded,
                          label: 'القائمة',
                          color: Colors.amber.shade800,
                          onTap: () => context.push('/manager/menu'),
                        ),

                        _QuickAction(
                          icon: Icons.table_restaurant_rounded,
                          label: 'الطاولات',
                          color: Colors.cyan.shade800,
                          onTap: () => context.push('/manager/tables'),
                        ),
                        _QuickAction(
                          icon: Icons.event_seat_rounded,
                          label: 'الحجوزات',
                          color: Colors.purple.shade700,
                          onTap: () => context.push('/manager/reservations'),
                        ),
                        _QuickAction(
                          icon: Icons.local_offer_rounded,
                          label: 'الخصومات',
                          color: Colors.deepOrange,
                          onTap: () => context.push('/manager/discounts'),
                        ),
                        _QuickAction(
                          icon: Icons.confirmation_number_rounded,
                          label: 'الكوبونات',
                          color: Colors.amber.shade800,
                          onTap: () => context.push('/manager/coupons'),
                        ),

                        _QuickAction(
                          icon: Icons.inventory_2_outlined,
                          label: 'المخزون',
                          color: Colors.teal,
                          onTap: () => context.push('/manager/inventory'),
                        ),
                        _QuickAction(
                          icon: Icons.people_alt_rounded,
                          label: 'الموظفون',
                          color: Colors.indigo,
                          onTap: () => context.push('/manager/staff'),
                        ),
                        _QuickAction(
                          icon: Icons.manage_accounts_rounded,
                          label: 'المستخدمون',
                          color: Colors.blueGrey.shade700,
                          onTap: () => context.push('/manager/users'),
                        ),

                        _QuickAction(
                          icon: Icons.local_shipping_rounded,
                          label: 'التوصيل',
                          color: Colors.deepPurple,
                          onTap: () => context.push('/manager/dispatch'),
                        ),
                        _QuickAction(
                          icon: Icons.receipt_long_rounded,
                          label: 'الفواتير',
                          color: Colors.brown,
                          onTap: () => context.push('/manager/invoices'),
                        ),
                        _QuickAction(
                          icon: Icons.analytics_outlined,
                          label: 'الأرباح و P&L',
                          color: Colors.green.shade800,
                          onTap: () =>
                              context.push('/manager/financial-reports'),
                        ),

                        _QuickAction(
                          icon: Icons.qr_code_2,
                          label: 'رموز QR',
                          color: Colors.blueGrey,
                          onTap: () => context.push('/manager/qr-codes'),
                        ),
                        _QuickAction(
                          icon: Icons.receipt_long,
                          label: 'الطلبات',
                          color: Colors.blue,
                          onTap: () => context.push('/manager/orders'),
                        ),
                      ],
                    ),

                    // ── Analytics Charts ──────────────────────────────────────────
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'التحليلات البيانية والمبيعات',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SalesLineChart(
                      salesData: {
                        'السبت': data.totalSales * 0.12,
                        'الأحد': data.totalSales * 0.14,
                        'الإثنين': data.totalSales * 0.10,
                        'الثلاثاء': data.totalSales * 0.15,
                        'الأربعاء': data.totalSales * 0.18,
                        'الخميس': data.totalSales * 0.22,
                        'الجمعة': data.totalSales * 0.25,
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TopItemsBarChart(itemsSold: data.itemsSold),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: PeakHoursChart(
                              hourlyDistribution: const {
                                12: 12,
                                13: 18,
                                14: 25,
                                15: 14,
                                16: 8,
                                17: 10,
                                18: 22,
                                19: 34,
                                20: 45,
                                21: 38,
                                22: 28,
                                23: 15,
                              },
                              peakHour: data.peakHour,
                            ),
                          ),
                        ],
                      )
                    else ...[
                      TopItemsBarChart(itemsSold: data.itemsSold),
                      const SizedBox(height: AppSpacing.md),
                      PeakHoursChart(
                        hourlyDistribution: const {
                          12: 12,
                          13: 18,
                          14: 25,
                          15: 14,
                          16: 8,
                          17: 10,
                          18: 22,
                          19: 34,
                          20: 45,
                          21: 38,
                          22: 28,
                          23: 15,
                        },
                        peakHour: data.peakHour,
                      ),
                    ],

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
                                  in data.itemsSold.entries.toList()..sort(
                                    (a, b) => b.value.compareTo(a.value),
                                  ))
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.xs,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(child: Text(entry.key)),
                                      Text(
                                        '${entry.value}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      AppConstants.metricsByCategory,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (data.categoryRevenue.isEmpty)
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
                                  in data.categoryRevenue.entries.toList()
                                    ..sort(
                                      (a, b) => b.value.compareTo(a.value),
                                    ))
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.xs,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(child: Text(entry.key)),
                                      Text(
                                        Formatters.formatCurrency(entry.value),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      AppConstants.metricsByPayment,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (data.paymentMethodRevenue.isEmpty)
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
                                  in data.paymentMethodRevenue.entries.toList()
                                    ..sort(
                                      (a, b) => b.value.compareTo(a.value),
                                    ))
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.xs,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(child: Text(entry.key)),
                                      Text(
                                        Formatters.formatCurrency(entry.value),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
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
          },
        ),
      ),
    );
  }

  String _activeOrders(WidgetRef ref) {
    final orders = ref.watch(ordersControllerProvider);
    final active = orders.where((o) => !o.status.isTerminal).length;
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
    return AnimatedPressCard(
      borderRadius: AppRadius.md,
      border: Border.all(color: color.withValues(alpha: 0.25), width: 1.0),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
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

/// Dispatch-health strip between the KPI cards and Quick Actions: live
/// pending-orders / failed-assignments / available-drivers counts that taps
/// through to the manual dispatch board.
class _DispatchHealthCard extends ConsumerWidget {
  const _DispatchHealthCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final board = ref.watch(dispatchControllerProvider);

    return AnimatedPressCard(
      key: const ValueKey('dispatch_health_card'),
      borderRadius: AppRadius.md,
      onTap: () => context.push('/manager/dispatch'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: board.when(
          loading: () => const Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: AppSpacing.sm),
              Text(AppConstants.dispatchHealthLoading),
            ],
          ),
          error: (_, _) => Row(
            children: [
              Icon(
                Icons.error_outline,
                size: 18,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: Text(AppConstants.dispatchHealthUnavailable),
              ),
            ],
          ),
          data: (state) => Row(
            children: [
              Expanded(
                child: _DispatchHealthStat(
                  label: AppConstants.dispatchHealthPendingOrders,
                  value: '${state.undispatchedOrders.length}',
                  color: Colors.orange.shade800,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _DispatchHealthStat(
                  label: AppConstants.dispatchHealthFailedAssignments,
                  value: '${state.failedAssignments.length}',
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _DispatchHealthStat(
                  label: AppConstants.dispatchHealthAvailableDrivers,
                  value: '${state.availableDrivers.length}',
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One labeled count inside [_DispatchHealthCard].
class _DispatchHealthStat extends StatelessWidget {
  const _DispatchHealthStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Live count of orders per status (chips shown when there is any activity).
class _StatusBreakdown extends StatelessWidget {
  const _StatusBreakdown({required this.orders});

  final List<OrderEntity> orders;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Text(AppConstants.metricsNoData),
        ),
      );
    }
    final counts = <OrderStatus, int>{};
    for (final order in orders) {
      counts[order.status] = (counts[order.status] ?? 0) + 1;
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final status in OrderStatus.values)
              if ((counts[status] ?? 0) > 0)
                Chip(
                  label: Text('${status.labelAr}: ${counts[status]}'),
                  visualDensity: VisualDensity.compact,
                ),
          ],
        ),
      ),
    );
  }
}

// ── Quick Action tile ──────────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
