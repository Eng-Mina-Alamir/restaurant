import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing.dart';
import '../../domain/entities/cash_drawer_transaction_entity.dart';
import '../controllers/cash_drawer_controller.dart';

/// Modal dialog for recording Cash Drawer Movements (Pay-In & Pay-Out / Petty Cash).
class CashDrawerInOutDialog extends ConsumerStatefulWidget {
  const CashDrawerInOutDialog({
    super.key,
    required this.shiftId,
  });

  final String shiftId;

  static Future<CashDrawerTransaction?> show(
    BuildContext context, {
    required String shiftId,
  }) {
    return showDialog<CashDrawerTransaction>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => CashDrawerInOutDialog(shiftId: shiftId),
    );
  }

  @override
  ConsumerState<CashDrawerInOutDialog> createState() =>
      _CashDrawerInOutDialogState();
}

class _CashDrawerInOutDialogState extends ConsumerState<CashDrawerInOutDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _reasonCtrl = TextEditingController();
  final TextEditingController _personCtrl = TextEditingController();
  final TextEditingController _pinCtrl = TextEditingController();

  static const List<String> _commonPayOutReasons = [
    'مشتريات طارئة للمطبخ / خضار',
    'شراء ثلج / مياه غازية',
    'مصروفات صيانة أو كهرباء',
    'إكراميات عمال نظافة / خدمات',
    'أدوات نظافة وتغليف',
  ];

  static const List<String> _commonPayInReasons = [
    'استلام فكة إضافية من الخزينة الرئيسية',
    'إيداع تسوية مبيعات سابقة',
    'سداد عهدة مؤقتة',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountCtrl.dispose();
    _reasonCtrl.dispose();
    _personCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = double.tryParse(_amountCtrl.text.trim());
    final reason = _reasonCtrl.text.trim();
    final person = _personCtrl.text.trim();
    final pin = _pinCtrl.text.trim();

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال مبلغ مالي صحيح أكبر من الصفر'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تحديد أو كتابة سبب حركة النقدية'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final isPayIn = _tabController.index == 0;
    final controller = ref.read(cashDrawerControllerProvider.notifier);

    final CashDrawerTransaction tx;
    if (isPayIn) {
      tx = controller.recordPayIn(
        shiftId: widget.shiftId,
        amount: amount,
        reason: reason,
        depositorName: person.isEmpty ? null : person,
        managerPin: pin.isEmpty ? null : pin,
      );
    } else {
      tx = controller.recordPayOut(
        shiftId: widget.shiftId,
        amount: amount,
        reason: reason,
        recipientName: person.isEmpty ? null : person,
        managerPin: pin.isEmpty ? null : pin,
      );
    }

    Navigator.of(context).pop(tx);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isPayIn
              ? 'تم تسجيل إيداع ${amount.toStringAsFixed(2)} ج.م بالدرج بنجاح ✅'
              : 'تم تسجيل سحب ${amount.toStringAsFixed(2)} ج.م مصروفات نثرية بنجاح ✅',
        ),
        backgroundColor: isPayIn ? const Color(0xFF10B981) : const Color(0xFFEA580C),
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
        constraints: const BoxConstraints(maxWidth: 480),
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
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Color(0xFF3B82F6),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'حركات الدرج والمصروفات النثرية',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'تسجيل سحب أو إيداع نقدية في صندوق الكاشير',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Tabs: Pay-In vs Pay-Out
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.arrow_downward_rounded, color: Colors.green),
                      text: 'إيداع نقدية (Pay-In)',
                    ),
                    Tab(
                      icon: Icon(Icons.arrow_upward_rounded, color: Colors.orange),
                      text: 'سحب مصروفات (Pay-Out)',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Amount Field
                const Text(
                  'المبلغ (ج.م) *',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.payments_outlined),
                    suffixText: 'ج.م',
                    hintText: '0.00',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Reason Selector / Input
                const Text(
                  'سبب الحركة *',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _reasonCtrl,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.receipt_outlined),
                    hintText: 'اكتب سبب الإيداع أو السحب...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Quick preset chips
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: (_tabController.index == 0
                          ? _commonPayInReasons
                          : _commonPayOutReasons)
                      .map((r) => ActionChip(
                            label: Text(r, style: const TextStyle(fontSize: 11)),
                            onPressed: () => setState(() => _reasonCtrl.text = r),
                          ))
                      .toList(),
                ),
                const SizedBox(height: AppSpacing.md),

                // Person name
                const Text(
                  'اسم المستلم / المودع (اختياري)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _personCtrl,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_outline),
                    hintText: 'مثال: الشيف أحمد / مسؤول الخزينة',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Manager PIN (required for audit; never logged).
                const Text(
                  'الرقم السري للمدير (للرقابة)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _pinCtrl,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    hintText: 'PIN المدير المعتمد',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
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
                          backgroundColor: colorScheme.primary,
                        ),
                        onPressed: _submit,
                        icon: const Icon(Icons.save_rounded),
                        label: const Text('حفظ وفتح الدرج'),
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
