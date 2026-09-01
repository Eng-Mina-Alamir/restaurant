import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/enums.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../orders/domain/entities/order_entity.dart';
import '../../domain/entities/order_refund_entity.dart';
import '../controllers/cash_drawer_controller.dart';
import 'manager_approval_dialog.dart';

/// Modal dialog for processing full or partial order returns & issuing refund credit receipts.
class OrderRefundDialog extends ConsumerStatefulWidget {
  const OrderRefundDialog({
    super.key,
    required this.order,
  });

  final OrderEntity order;

  static Future<OrderRefundRecord?> show(
    BuildContext context, {
    required OrderEntity order,
  }) {
    return showDialog<OrderRefundRecord>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => OrderRefundDialog(order: order),
    );
  }

  @override
  ConsumerState<OrderRefundDialog> createState() => _OrderRefundDialogState();
}

class _OrderRefundDialogState extends ConsumerState<OrderRefundDialog> {
  late PaymentMethod _refundMethod;
  final TextEditingController _reasonCtrl = TextEditingController();
  final TextEditingController _customAmountCtrl = TextEditingController();
  bool _isFullRefund = true;

  static const List<String> _commonRefundReasons = [
    'تأخير زائد في تحضير الطلب',
    'خطأ في مكونات الصنف من المطبخ',
    'جودة الصنف غير مطابقة لرغبة العميل',
    'طلب العميل الإلغاء قبل التحضير',
  ];

  @override
  void initState() {
    super.initState();
    _refundMethod = widget.order.paymentMethod ?? PaymentMethod.cash;
    _customAmountCtrl.text = widget.order.totalAmount.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _customAmountCtrl.dispose();
    super.dispose();
  }

  double get _calculatedRefundAmount {
    if (_isFullRefund) return widget.order.totalAmount;
    return double.tryParse(_customAmountCtrl.text.trim()) ?? 0.0;
  }

  Future<void> _processRefund() async {
    final amount = _calculatedRefundAmount;
    final reason = _reasonCtrl.text.trim();

    if (amount <= 0 || amount > widget.order.totalAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تحديد مبلغ استرجاع صحيح لا يتجاوز إجمالي الفاتورة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى كتابة أو تحديد سبب الاسترجاع'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Require Manager PIN Approval for any refund transaction
    final approved = await ManagerApprovalDialog.show(
      context,
      action: ManagerApprovalAction.voidOrder,
      targetDescription:
          'استرجاع فاتورة #${Formatters.formatOrderId(widget.order.id)} بقيمة ${Formatters.formatCurrency(amount)}',
    );

    if (approved != true) return;

    final refundRecord = OrderRefundRecord(
      id: 'REF-${DateTime.now().millisecondsSinceEpoch}',
      originalOrderId: widget.order.id,
      refundAmount: amount,
      refundMethod: _refundMethod,
      reason: reason,
      refundedAt: DateTime.now(),
      refundedItemNames: widget.order.items.map((i) => i.menuItem.name).toList(),
    );

    // Record refund in cash drawer
    ref.read(cashDrawerControllerProvider.notifier).recordRefund(refundRecord);

    if (!mounted) return;
    Navigator.of(context).pop(refundRecord);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم تسجيل استرجاع ${Formatters.formatCurrency(amount)} وإصدار الإشعار الدائن بنجاح ✅',
        ),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
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
                        color: Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(
                        Icons.assignment_return_rounded,
                        color: Colors.red,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'استرجاع فاتورة #${Formatters.formatOrderId(widget.order.id)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'إصدار إشعار دائن (Refund Receipt) وإرجاع المبلغ',
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

                // Refund Type Selector (Full vs Partial)
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('استرجاع كامل الفاتورة')),
                    ButtonSegment(value: false, label: Text('استرجاع جزئي / مبلغ محدد')),
                  ],
                  selected: {_isFullRefund},
                  onSelectionChanged: (s) {
                    setState(() {
                      _isFullRefund = s.first;
                      if (_isFullRefund) {
                        _customAmountCtrl.text = widget.order.totalAmount.toStringAsFixed(2);
                      }
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                if (!_isFullRefund) ...[
                  TextField(
                    controller: _customAmountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'مبلغ الاسترجاع (ج.م) *',
                      suffixText: 'ج.م',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Reason input
                const Text(
                  'سبب الاسترجاع *',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _reasonCtrl,
                  decoration: InputDecoration(
                    hintText: 'اكتب أو اختر سبب الاسترجاع...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: _commonRefundReasons
                      .map((r) => ActionChip(
                            label: Text(r, style: const TextStyle(fontSize: 11)),
                            onPressed: () => setState(() => _reasonCtrl.text = r),
                          ))
                      .toList(),
                ),
                const SizedBox(height: AppSpacing.md),

                // Refund Payment Method
                const Text(
                  'طريقة رد المبلغ للعميل:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                SegmentedButton<PaymentMethod>(
                  segments: const [
                    ButtonSegment(value: PaymentMethod.cash, label: Text('💵 كاش من الدرج')),
                    ButtonSegment(value: PaymentMethod.card, label: Text('💳 إلى البطاقة')),
                  ],
                  selected: {_refundMethod},
                  onSelectionChanged: (s) => setState(() => _refundMethod = s.first),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Action Buttons
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
                          backgroundColor: Colors.red.shade700,
                        ),
                        onPressed: _processRefund,
                        icon: const Icon(Icons.lock_person_rounded),
                        label: const Text('طلب موافقة المدير وتأكيد المرتجع'),
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
