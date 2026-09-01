import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/enums.dart';
import '../../../../core/theme/color_schemes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/constrained_content_view.dart';
import '../../../orders/presentation/controllers/orders_controller.dart';
import '../controllers/sales_target_controller.dart';

/// Hourly Sales Velocity & Daily Target Progress Tracker for Restaurant Managers.
class SalesVelocityTargetPage extends ConsumerWidget {
  const SalesVelocityTargetPage({super.key});

  void _showSetTargetDialog(BuildContext context, WidgetRef ref, double currentTarget) {
    final targetCtrl = TextEditingController(text: currentTarget.toStringAsFixed(0));

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('تعديل تارجت المبيعات اليومي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: targetCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'الهدف اليومي (ج.م)',
                    suffixText: 'ج.م',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: () {
                          final val = double.tryParse(targetCtrl.text.trim());
                          if (val != null && val > 0) {
                            ref.read(salesTargetControllerProvider.notifier).setDailyTarget(val);
                          }
                          Navigator.of(ctx).pop();
                        },
                        child: const Text('حفظ التارجت'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final targetState = ref.watch(salesTargetControllerProvider);
    final orders = ref.watch(ordersControllerProvider);
    final completedOrders = orders.where((o) => o.status == OrderStatus.completed).toList();

    final progress = targetState.computeDailyProgress(completedOrders);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تارجت المبيعات وسرعة البيع بالساعة (Sales Velocity)'),
        actions: [
          IconButton(
            tooltip: 'تعديل التارجت',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => _showSetTargetDialog(context, ref, targetState.dailyTarget),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: ConstrainedContentView(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // ── 1. Daily Target Progress Card ────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: AppGradients.primary,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'إنجاز التارجت اليومي للمطعم (Daily Revenue Target)',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          'تارجت: ${Formatters.formatCurrency(progress.dailyTarget)}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${progress.percentageAchieved}%',
                        style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'محقق: ${Formatters.formatCurrency(progress.currentSales)}',
                        style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (progress.percentageAchieved / 100).clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF34D399)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.sm,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      _MiniMetric(label: 'إجمالي الفواتير:', value: '${progress.totalOrdersCount} طلب'),
                      _MiniMetric(label: 'متوسط الفاتورة (Ticket):', value: Formatters.formatCurrency(progress.averageTicketSize)),
                      _MiniMetric(
                        label: 'ذروة اليوم:',
                        value: progress.peakRushHour != null ? progress.peakRushHour!.hourFormattedAr : 'بانتظار الذروة',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── 2. Hourly Sales Velocity Breakdown ───────────────────────────
            Text(
              'سرعة المبيعات وعدد الطلبات في كل ساعة من اليوم (Hourly Velocity)',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: progress.hourlyPoints.length,
              separatorBuilder: (ctx, index) => const SizedBox(height: 6),
              itemBuilder: (ctx, index) {
                final point = progress.hourlyPoints[index];
                final isPeak = point.isRushPeakHour;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? colorScheme.surfaceContainerLow : Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: isPeak ? const Color(0xFFF59E0B) : colorScheme.outlineVariant.withValues(alpha: 0.3),
                      width: isPeak ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 70,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: isPeak ? const Color(0xFFFEF3C7) : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Center(
                          child: Text(
                            point.hourFormattedAr,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isPeak ? const Color(0xFFB45309) : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  Formatters.formatCurrency(point.salesAmount),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                Text(
                                  '${point.ordersCount} طلبات',
                                  style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: point.targetAmount > 0
                                    ? (point.salesAmount / point.targetAmount).clamp(0.0, 1.0)
                                    : 0.0,
                                minHeight: 4,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isPeak ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isPeak) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 20),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
