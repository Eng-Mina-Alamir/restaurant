import 'package:flutter/material.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/cashier_discount_entity.dart';
import 'manager_approval_dialog.dart';

/// Modal dialog for applying discounts, promo comps, and staff meals with manager authorization.
class CashierDiscountDialog extends StatefulWidget {
  const CashierDiscountDialog({
    super.key,
    required this.orderSubtotal,
    this.currentDiscount,
  });

  final double orderSubtotal;
  final CashierDiscount? currentDiscount;

  static Future<CashierDiscount?> show(
    BuildContext context, {
    required double orderSubtotal,
    CashierDiscount? currentDiscount,
  }) {
    return showDialog<CashierDiscount>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => CashierDiscountDialog(
        orderSubtotal: orderSubtotal,
        currentDiscount: currentDiscount,
      ),
    );
  }

  @override
  State<CashierDiscountDialog> createState() => _CashierDiscountDialogState();
}

class _CashierDiscountDialogState extends State<CashierDiscountDialog> {
  CashierDiscount? _selectedPreset;
  bool _isCustom = false;
  final TextEditingController _customValueCtrl = TextEditingController();
  final TextEditingController _reasonCtrl = TextEditingController();
  DiscountType _customType = DiscountType.percentage;

  @override
  void initState() {
    super.initState();
    _selectedPreset = widget.currentDiscount;
  }

  @override
  void dispose() {
    _customValueCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyDiscount() async {
    CashierDiscount discountToApply;

    if (_isCustom) {
      final val = double.tryParse(_customValueCtrl.text.trim());
      if (val == null || val <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يرجى إدخال قيمة خصم صحيحة أكبر من الصفر'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final requiresPin = (_customType == DiscountType.percentage && val > 15) ||
          (_customType == DiscountType.fixedAmount && val > 50);

      discountToApply = CashierDiscount(
        id: 'disc-custom-${DateTime.now().millisecondsSinceEpoch}',
        nameAr: _customType == DiscountType.percentage
            ? 'خصم مخصص $val%'
            : 'خصم مخصص ${val.toStringAsFixed(0)} ج.م',
        type: _customType,
        value: val,
        requiresManagerPin: requiresPin,
        reason: _reasonCtrl.text.trim().isEmpty ? 'خصم مخصص' : _reasonCtrl.text.trim(),
      );
    } else {
      if (_selectedPreset == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى اختيار نوع الخصم')),
        );
        return;
      }
      discountToApply = _selectedPreset!;
    }

    // Check Manager PIN if required
    if (discountToApply.requiresManagerPin) {
      final approved = await ManagerApprovalDialog.show(
        context,
        action: discountToApply.type == DiscountType.complimentary
            ? ManagerApprovalAction.fullDiscount
            : ManagerApprovalAction.priceOverride,
        targetDescription: discountToApply.nameAr,
      );

      if (approved != true) {
        return; // Manager denied or cancelled
      }
    }

    if (!mounted) return;
    Navigator.of(context).pop(discountToApply);
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
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(
                        Icons.percent_rounded,
                        color: Color(0xFF8B5CF6),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'تطبيق خصم أو ضيافة إدارة',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'إجمالي الفاتورة: ${Formatters.formatCurrency(widget.orderSubtotal)}',
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

                // Preset Discounts
                const Text(
                  'قائمة الخصومات المعتمدة:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                ...CashierDiscount.presets.map((preset) {
                  final isSelected = !_isCustom && _selectedPreset?.id == preset.id;
                  final discountAmount = preset.calculateDiscountAmount(widget.orderSubtotal);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF8B5CF6).withValues(alpha: 0.12)
                          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF8B5CF6)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: isSelected
                            ? const Color(0xFF8B5CF6)
                            : Colors.grey,
                      ),
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(
                              preset.nameAr,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (preset.requiresManagerPin) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.lock, size: 10, color: Colors.orange),
                                  SizedBox(width: 2),
                                  Text('PIN المدير', style: TextStyle(fontSize: 9, color: Colors.orange, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      trailing: Text(
                        '- ${Formatters.formatCurrency(discountAmount)}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _isCustom = false;
                          _selectedPreset = preset;
                        });
                      },
                    ),
                  );
                }),

                const SizedBox(height: AppSpacing.sm),

                // Custom Discount Toggle Option
                CheckboxListTile(
                  title: const Text('خصم مخصص أو مبلغ استثنائي', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  value: _isCustom,
                  dense: true,
                  onChanged: (val) => setState(() => _isCustom = val ?? false),
                ),

                if (_isCustom) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customValueCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: _customType == DiscountType.percentage ? 'النسبة (%)' : 'المبلغ (ج.م)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SegmentedButton<DiscountType>(
                        segments: const [
                          ButtonSegment(value: DiscountType.percentage, label: Text('%')),
                          ButtonSegment(value: DiscountType.fixedAmount, label: Text('ج.م')),
                        ],
                        selected: {_customType},
                        onSelectionChanged: (s) => setState(() => _customType = s.first),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reasonCtrl,
                    decoration: InputDecoration(
                      labelText: 'سبب الخصم الاستثنائي *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                      isDense: true,
                    ),
                  ),
                ],

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
                          backgroundColor: const Color(0xFF8B5CF6),
                        ),
                        onPressed: _applyDiscount,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('تطبيق الخصم'),
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
