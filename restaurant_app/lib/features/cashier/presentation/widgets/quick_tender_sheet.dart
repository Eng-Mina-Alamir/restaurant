import 'package:flutter/material.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/services/quick_tender_service.dart';

/// Modal bottom sheet for ultra-fast Cash Tender calculation and Change Due display.
class QuickTenderSheet extends StatefulWidget {
  const QuickTenderSheet({
    super.key,
    required this.totalAmountDue,
    required this.onCompletePayment,
  });

  final double totalAmountDue;
  final ValueChanged<double> onCompletePayment;

  /// Helper to present the Quick Tender modal sheet
  static Future<double?> show(
    BuildContext context, {
    required double totalAmountDue,
  }) {
    return showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => QuickTenderSheet(
            totalAmountDue: totalAmountDue,
            onCompletePayment: (tendered) => Navigator.of(ctx).pop(tendered),
          ),
    );
  }

  @override
  State<QuickTenderSheet> createState() => _QuickTenderSheetState();
}

class _QuickTenderSheetState extends State<QuickTenderSheet> {
  late double _tenderedAmount;
  final TextEditingController _customCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tenderedAmount = widget.totalAmountDue;
    _customCtrl.text = widget.totalAmountDue.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  void _selectTender(double amount) {
    setState(() {
      _tenderedAmount = amount;
      _customCtrl.text = amount.toStringAsFixed(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final changeDue = QuickTenderService.calculateChangeDue(
      totalDue: widget.totalAmountDue,
      tenderedAmount: _tenderedAmount,
    );
    final isSufficient = QuickTenderService.isTenderSufficient(
      totalDue: widget.totalAmountDue,
      tenderedAmount: _tenderedAmount,
    );
    final suggestedBills = QuickTenderService.calculateSuggestedTenders(
      widget.totalAmountDue,
    );

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

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
                  Icons.payments_rounded,
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
                      'حاسبة النقدية والباقي (Cash Tender)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'إجمالي الحساب المطلوب: ${Formatters.formatCurrency(widget.totalAmountDue)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Big Change Due Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isSufficient
                    ? [const Color(0xFF059669), const Color(0xFF10B981)]
                    : [const Color(0xFFDC2626), const Color(0xFFEF4444)],
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: [
                BoxShadow(
                  color: (isSufficient
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444))
                      .withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  isSufficient
                      ? 'الباقي للعميل (Change Due)'
                      : 'المبلغ المدفوع غير كافٍ!',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isSufficient
                      ? Formatters.formatCurrency(changeDue)
                      : 'متبقي: ${Formatters.formatCurrency(widget.totalAmountDue - _tenderedAmount)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Suggested Bill Chips
          const Text(
            'فئات نقدية سريعة:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestedBills.map((bill) {
              final isSelected = (_tenderedAmount - bill).abs() < 0.01;
              final isExact = (bill - widget.totalAmountDue).abs() < 0.01;

              return ChoiceChip(
                label: Text(
                  isExact
                      ? 'المبلغ بالضبط (${Formatters.formatCurrency(bill)})'
                      : Formatters.formatCurrency(bill),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : null,
                  ),
                ),
                selected: isSelected,
                selectedColor: const Color(0xFF10B981),
                onSelected: (_) => _selectTender(bill),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),

          // Custom Amount Input
          TextField(
            controller: _customCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (val) {
              final parsed = double.tryParse(val.trim()) ?? 0.0;
              setState(() => _tenderedAmount = parsed);
            },
            decoration: InputDecoration(
              labelText: 'أو اكتب المبلغ المستلم يدوياً',
              suffixText: 'ج.م',
              prefixIcon: const Icon(Icons.edit_note_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              filled: true,
              fillColor: isDark ? colorScheme.surfaceContainerLow : Colors.grey.shade50,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Confirm & Open Drawer Action Button
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: isSufficient
                  ? const Color(0xFF10B981)
                  : Colors.grey,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            onPressed: isSufficient
                ? () => widget.onCompletePayment(_tenderedAmount)
                : null,
            icon: const Icon(Icons.check_circle_rounded),
            label: const Text(
              'تأكيد الدفع وفتح الدرج 💵',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
