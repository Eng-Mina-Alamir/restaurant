import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../shared/widgets/humanized_feedback.dart';
import '../controllers/driver_wallet_controller.dart';
import 'change_calculator_dialog.dart';

/// Compact floating cash & float summary bar for delivery drivers.
class DriverCashSummaryCard extends ConsumerWidget {
  const DriverCashSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(driverWalletControllerProvider);
    final theme = Theme.of(context);
    final success = StatusColors.tone(
      SemanticTone.success,
      theme.brightness,
    );

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              color: success,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'عهدة الكاش بأمان معك',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  Formatters.formatCurrency(wallet.totalCashInHand),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 48),
            ),
            onPressed: () {
              AppHaptics.selectionTap();
              ChangeCalculatorDialog.show(context, orderTotal: 150.0);
            },
            icon: const Icon(Icons.calculate_outlined, size: 18),
            label: const Text('حاسبة الباقي'),
          ),
          const SizedBox(width: AppSpacing.xs),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 48),
            ),
            onPressed: () => _showSettleConfirmation(context, ref, wallet),
            child: Text(
              wallet.isSettled ? 'تم التسليم — شكراً لك' : 'تسليم للكاشير',
            ),
          ),
          IconButton(
            tooltip: 'تقرير الأرباح والعمولات',
            style: IconButton.styleFrom(
              minimumSize: const Size(48, 48),
            ),
            icon: Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.chevron_left_rounded
                  : Icons.chevron_right_rounded,
              size: 22,
            ),
            onPressed: () => context.push('/driver/earnings'),
          ),
        ],
      ),
    );
  }

  void _showSettleConfirmation(
    BuildContext context,
    WidgetRef ref,
    dynamic wallet,
  ) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  color: StatusColors.tone(
                    SemanticTone.success,
                    Theme.of(context).brightness,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Expanded(
                  child: Text('تصفية العهدة وتسليم الكاش بكل أمان'),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'سلّم المبالغ التالية لكاشير المطعم لإغلاق حساب الوردية — شكراً لأمانتك:',
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(height: 1.6),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _buildRow(
                        'عهدة البداية:',
                        Formatters.formatCurrency(wallet.openingFloat),
                      ),
                      const SizedBox(height: 6),
                      _buildRow(
                        'كاش الوجبات المحصل:',
                        Formatters.formatCurrency(wallet.collectedCod),
                      ),
                      const Divider(height: 16),
                      _buildRow(
                        'إجمالي المبلغ المسلّم للكاشير:',
                        Formatters.formatCurrency(
                          wallet.remittanceDueToCashier,
                        ),
                        isBold: true,
                        color: StatusColors.tone(
                          SemanticTone.success,
                          Theme.of(ctx).brightness,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildRow(
                        'أرباحك المحتفظ بها (عمولة + إكرامية):',
                        Formatters.formatCurrency(wallet.totalDriverEarnings),
                        color: StatusColors.tone(
                          SemanticTone.info,
                          Theme.of(ctx).brightness,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () {
                  AppHaptics.milestoneSuccess();
                  ref.read(driverWalletControllerProvider.notifier).settleShift();
                  Navigator.pop(ctx);
                  HumanSnackBar.milestone(
                    context,
                    'تم تسليم العهدة بنجاح — شكراً لأمانتك وجهدك',
                  );
                },
                child: const Text('تأكيد التسليم للكاشير'),
              ),
            ],
          ),
    );
  }

  Widget _buildRow(
    String title,
    String val, {
    bool isBold = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          val,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
