import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../controllers/waiter_shift_controller.dart';

/// Screen displaying the active waiter's shift statistics, sales volume, tip collection, and remittance.
class WaiterTipsPage extends ConsumerWidget {
  const WaiterTipsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final stats = ref.watch(waiterShiftControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير إكراميات وأداء الوردية'),
        actions: [
          IconButton(
            tooltip: 'تحديث البيانات',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(waiterShiftControllerProvider),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // 1. Captain Profile Banner
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFF3B82F6),
                      child: Text(
                        stats.waiterName.isNotEmpty
                            ? stats.waiterName.substring(0, 1)
                            : 'W',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stats.waiterName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'كابتن صالة معتمد • وردية ${Formatters.formatDate(stats.shiftDate)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            stats.isShiftSettled
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        stats.isShiftSettled ? 'الوردية مقفلة ✅' : 'وردية نشطة 🟢',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.white24, height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol(
                      'إجمالي الإكراميات',
                      Formatters.formatCurrency(stats.totalTips),
                      const Color(0xFF10B981),
                    ),
                    _buildStatCol(
                      'مبيعات الصالة',
                      Formatters.formatCurrency(stats.totalSalesVolume),
                      Colors.white,
                    ),
                    _buildStatCol(
                      'طاولات مخدومة',
                      '${stats.tablesServedCount}',
                      const Color(0xFF3B82F6),
                    ),
                    _buildStatCol(
                      'ضيوف مخدومين',
                      '${stats.guestsServedCount}',
                      const Color(0xFFF59E0B),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 2. Tips Breakdown Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.payments_outlined,
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'تفصيل الإكراميات والتبس (Tips Breakdown)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTipRow(
                    'إكراميات نقدية (Cash in Pocket):',
                    Formatters.formatCurrency(stats.cashTipsCollected),
                    Icons.account_balance_wallet_outlined,
                    const Color(0xFF10B981),
                  ),
                  const Divider(height: 16),
                  _buildTipRow(
                    'إكراميات مدفوعة بالفيزا (Card Tips):',
                    Formatters.formatCurrency(stats.creditTipsCollected),
                    Icons.credit_card_outlined,
                    const Color(0xFF3B82F6),
                  ),
                  const Divider(height: 16),
                  _buildTipRow(
                    'نسبة التبس من المبيعات:',
                    '${stats.tipPercentageOnSales.toStringAsFixed(1)} %',
                    Icons.percent_rounded,
                    const Color(0xFFF59E0B),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 3. Settlement / Closing Action
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor:
                  stats.isShiftSettled
                      ? Colors.grey
                      : const Color(0xFF10B981),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.receipt_long_rounded),
            label: Text(
              stats.isShiftSettled
                  ? 'تم تقفيل الوردية وتسليم الحساب للكاشير'
                  : 'تصفية وإغلاق الوردية وتسليم الكاش للكاشير',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed:
                stats.isShiftSettled
                    ? null
                    : () {
                      ref
                          .read(waiterShiftControllerProvider.notifier)
                          .settleShift();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'تم إغلاق وتصفية وردية الكابتن بنجاح وتسليم التقرير ✅',
                          ),
                          backgroundColor: Color(0xFF10B981),
                        ),
                      );
                    },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCol(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildTipRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 13)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: color,
          ),
        ),
      ],
    );
  }
}
