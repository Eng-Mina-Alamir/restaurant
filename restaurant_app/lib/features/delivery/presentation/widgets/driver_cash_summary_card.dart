import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../controllers/driver_wallet_controller.dart';
import 'change_calculator_dialog.dart';

/// Compact floating cash & float summary bar for delivery drivers.
class DriverCashSummaryCard extends ConsumerWidget {
  const DriverCashSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(driverWalletControllerProvider);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 4,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.account_balance_wallet_rounded,
            color: Color(0xFF10B981),
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            'عهدة الكاش: ${Formatters.formatCurrency(wallet.totalCashInHand)}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11.5,
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: () => ChangeCalculatorDialog.show(context, orderTotal: 150.0),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.calculate_outlined,
                    color: Colors.white70,
                    size: 14,
                  ),
                  SizedBox(width: 2),
                  Text(
                    'حاسبة',
                    style: TextStyle(color: Colors.white70, fontSize: 10.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _showSettleConfirmation(context, ref, wallet),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color:
                    wallet.isSettled ? Colors.grey : const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                wallet.isSettled ? 'مسلّم ✅' : 'تسليم للكاشير',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            tooltip: 'تقرير الأرباح',
            icon: const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white70,
              size: 18,
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
            title: const Row(
              children: [
                Icon(Icons.receipt_long_rounded, color: Color(0xFF10B981)),
                SizedBox(width: 8),
                Text('تصفية العهدة وتسليم الكاش'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'يرجى تسليم المبالغ التالية إلى كاشير المطعم لإغلاق حساب الشيفت:',
                  style: TextStyle(fontSize: 13),
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
                        color: const Color(0xFF10B981),
                      ),
                      const SizedBox(height: 6),
                      _buildRow(
                        'أرباحك المحتفظ بها (عمولة + تبس):',
                        Formatters.formatCurrency(wallet.totalDriverEarnings),
                        color: const Color(0xFF3B82F6),
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
                  ref.read(driverWalletControllerProvider.notifier).settleShift();
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم تسليم العهدة وتصفية الشيفت بنجاح ✅'),
                      backgroundColor: Color(0xFF10B981),
                    ),
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
