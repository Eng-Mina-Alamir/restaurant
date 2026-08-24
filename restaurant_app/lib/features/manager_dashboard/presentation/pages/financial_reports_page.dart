import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/services/report_export_service.dart';
import '../controllers/financial_reports_controller.dart';

class FinancialReportsPage extends ConsumerWidget {
  const FinancialReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(financialReportsControllerProvider);
    final metrics = state.metrics;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير المالية والأرباح (P&L)'),
        actions: [
          IconButton(
            tooltip: 'تصدير تقرير مالي CSV',
            icon: const Icon(Icons.download_outlined),
            onPressed: () {
              final exportService = ref.read(reportExportServiceProvider);
              final _ = exportService.generateFinancialReportCsv(
                metrics,
                state.selectedPeriod.labelAr,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'تم تصدير تقرير بيان الأرباح والخسائر (${state.selectedPeriod.labelAr}) بنجاح!',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'تحديث البيانات',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref
                  .read(financialReportsControllerProvider.notifier)
                  .setPeriod(state.selectedPeriod);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Period Selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final period in FinancialPeriod.values)
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.xs),
                      child: ChoiceChip(
                        label: Text(period.labelAr),
                        selected: state.selectedPeriod == period,
                        onSelected: (selected) {
                          if (selected) {
                            ref
                                .read(
                                  financialReportsControllerProvider.notifier,
                                )
                                .setPeriod(period);
                          }
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Top Primary KPI Cards
            Row(
              children: [
                Expanded(
                  child: _KpiCard(
                    title: 'إجمالي المبيعات',
                    value: Formatters.formatCurrency(metrics.grossRevenue),
                    subtitle: '${metrics.completedOrders} طلب مكتمل',
                    icon: Icons.account_balance_wallet_outlined,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _KpiCard(
                    title: 'صافي الأرباح (Net Profit)',
                    value: Formatters.formatCurrency(metrics.netProfit),
                    subtitle:
                        'هامش صافي: ${metrics.netMarginPercentage.toStringAsFixed(1)}%',
                    icon: Icons.trending_up,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            Row(
              children: [
                Expanded(
                  child: _KpiCard(
                    title: 'تكلفة المواد (COGS)',
                    value: Formatters.formatCurrency(metrics.cogs),
                    subtitle: '30% من المبيعات',
                    icon: Icons.inventory_2_outlined,
                    color: Colors.deepOrange,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _KpiCard(
                    title: 'متوسط الفاتورة (AOV)',
                    value: Formatters.formatCurrency(metrics.averageOrderValue),
                    subtitle: 'لكل طلب مكتمل',
                    icon: Icons.receipt_long_outlined,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Profit & Loss Breakdown Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📊 تحليل بيان الأرباح والخسائر (Income Statement)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _FinancialRow(
                      label: '(+) إجمالي الإيرادات (Gross Revenue)',
                      amount: metrics.grossRevenue,
                      isPositive: true,
                      isBold: true,
                    ),
                    const Divider(),
                    _FinancialRow(
                      label: '(-) تكلفة البضاعة المباعة (COGS ~30%)',
                      amount: -metrics.cogs,
                      isPositive: false,
                    ),
                    const Divider(),
                    _FinancialRow(
                      label: '(=) مجمل الربح (Gross Profit)',
                      amount: metrics.grossRevenue - metrics.cogs,
                      isPositive: true,
                      percentage: metrics.grossMarginPercentage,
                      isBold: true,
                    ),
                    const Divider(),
                    _FinancialRow(
                      label: '(-) المصروفات التشغيلية والعمالة (~25%)',
                      amount: -metrics.operatingCosts,
                      isPositive: false,
                    ),
                    const Divider(thickness: 2),
                    _FinancialRow(
                      label: '(=) صافي الربح التشغيلي (Net Income)',
                      amount: metrics.netProfit,
                      isPositive: metrics.netProfit >= 0,
                      percentage: metrics.netMarginPercentage,
                      isBold: true,
                      highlight: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Top Profitable Products
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.star_rounded, color: Colors.amber),
                        SizedBox(width: 8),
                        Text(
                          'الأصناف الأكثر مساهمة في الأرباح',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.sm),
                    if (metrics.topProfitableItems.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text('لا توجد بيانات مبيعات في هذه الفترة'),
                        ),
                      )
                    else
                      for (final item in metrics.topProfitableItems)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            item.itemName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${item.unitsSold} قطعة مباعة • تكلفة تقديرية: ${Formatters.formatCurrency(item.estimatedCost)}',
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                Formatters.formatCurrency(item.profit),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              Text(
                                'هامش ${item.marginPercent.toStringAsFixed(0)}%',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
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
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

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
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinancialRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isPositive;
  final double? percentage;
  final bool isBold;
  final bool highlight;

  const _FinancialRow({
    required this.label,
    required this.amount,
    required this.isPositive,
    this.percentage,
    this.isBold = false,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      fontSize: highlight ? 15 : 13,
      color: highlight
          ? (isPositive ? Colors.green.shade800 : Colors.red.shade800)
          : null,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: textStyle)),
          Row(
            children: [
              if (percentage != null)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    '${percentage!.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              Text(Formatters.formatCurrency(amount.abs()), style: textStyle),
            ],
          ),
        ],
      ),
    );
  }
}
