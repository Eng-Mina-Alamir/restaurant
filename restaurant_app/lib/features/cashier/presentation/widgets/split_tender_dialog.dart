import 'package:flutter/material.dart';

import '../../../../core/domain/enums.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/split_tender_payment_entity.dart';
import '../../domain/services/split_tender_service.dart';

/// Modal dialog for split tender (paying one bill with multiple payment methods).
class SplitTenderDialog extends StatefulWidget {
  const SplitTenderDialog({
    super.key,
    required this.orderId,
    required this.totalAmountDue,
  });

  final String orderId;
  final double totalAmountDue;

  static Future<SplitTenderResult?> show(
    BuildContext context, {
    required String orderId,
    required double totalAmountDue,
  }) {
    return showDialog<SplitTenderResult>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => SplitTenderDialog(
        orderId: orderId,
        totalAmountDue: totalAmountDue,
      ),
    );
  }

  @override
  State<SplitTenderDialog> createState() => _SplitTenderDialogState();
}

class _SplitTenderDialogState extends State<SplitTenderDialog> {
  late SplitTenderResult _result;
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _refCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _result = SplitTenderResult(
      orderId: widget.orderId,
      totalAmountDue: widget.totalAmountDue,
      payments: const [],
    );
    _amountCtrl.text = widget.totalAmountDue.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  void _addPayment() {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال مبلغ صحيح أكبر من الصفر'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _result = SplitTenderService.addPaymentShare(
        currentResult: _result,
        method: _selectedMethod,
        amount: amount,
        referenceNumber: _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim(),
      );

      final nextRemaining = _result.remainingBalance;
      _amountCtrl.text = nextRemaining > 0 ? nextRemaining.toStringAsFixed(0) : '0';
      _refCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final remaining = _result.remainingBalance;
    final isSettled = _result.isFullyPaid;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(
                        Icons.call_split_rounded,
                        color: Color(0xFF10B981),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'الدفع المجزأ (Split Tender)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'سداد الفاتورة بأكثر من وسيلة دفع (كاش + فيزا + محفظة)',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(),
                const SizedBox(height: AppSpacing.xs),

                // Balance Tracker Card
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? colorScheme.surfaceContainerLow : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: isSettled ? Colors.green : Colors.orange,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('إجمالي الفاتورة:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Text(
                              Formatters.formatCurrency(widget.totalAmountDue),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text('المسدد حتى الآن:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Text(
                              Formatters.formatCurrency(_result.totalPaid),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('المتبقي للتحصيل:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Text(
                              Formatters.formatCurrency(remaining),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: isSettled ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Paid Shares List
                if (_result.payments.isNotEmpty) ...[
                  const Text(
                    'الدفعات المسجلة بالفاتورة:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  ..._result.payments.map((p) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                p.method == PaymentMethod.cash
                                    ? Icons.money
                                    : p.method == PaymentMethod.card
                                        ? Icons.credit_card
                                        : Icons.account_balance_wallet,
                                size: 16,
                                color: const Color(0xFF15803D),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                p.method.labelAr,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF15803D),
                                  fontSize: 12,
                                ),
                              ),
                              if (p.referenceNumber != null) ...[
                                const SizedBox(width: 6),
                                Text('(#${p.referenceNumber})', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ],
                          ),
                          Text(
                            Formatters.formatCurrency(p.amount),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF15803D),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: AppSpacing.sm),
                ],

                // New Payment Form (if not yet settled)
                if (!isSettled) ...[
                  const Text(
                    'إضافة وسيلة دفع للحساب المتبقي:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),

                  // Payment method selector
                  SegmentedButton<PaymentMethod>(
                    segments: const [
                      ButtonSegment(
                        value: PaymentMethod.cash,
                        label: Text('💵 كاش'),
                      ),
                      ButtonSegment(
                        value: PaymentMethod.card,
                        label: Text('💳 بطاقة / فيزا'),
                      ),
                      ButtonSegment(
                        value: PaymentMethod.wallet,
                        label: Text('📱 محفظة'),
                      ),
                    ],
                    selected: {_selectedMethod},
                    onSelectionChanged: (s) => setState(() => _selectedMethod = s.first),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _amountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'المبلغ المسدد بهذه الوسيلة',
                            suffixText: 'ج.م',
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _addPayment,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('تسجيل الدفعة'),
                      ),
                    ],
                  ),
                  if (_selectedMethod != PaymentMethod.cash) ...[
                    const SizedBox(height: 6),
                    TextField(
                      controller: _refCtrl,
                      decoration: InputDecoration(
                        labelText: 'رقم الإيصال / الرقم المرجعي للفيزا أو المحفظة',
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                      ),
                    ),
                  ],
                ],

                const SizedBox(height: AppSpacing.lg),

                // Final Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: isSettled ? const Color(0xFF10B981) : Colors.grey,
                        ),
                        onPressed: isSettled ? () => Navigator.of(context).pop(_result) : null,
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text('إتمام سداد الفاتورة بنجاح'),
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
}
