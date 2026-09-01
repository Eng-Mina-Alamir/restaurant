import 'package:flutter/material.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/services/driver_quick_action_service.dart';

/// Interactive change calculator dialog for drivers in the field.
class ChangeCalculatorDialog extends StatefulWidget {
  const ChangeCalculatorDialog({
    super.key,
    required this.orderTotal,
  });

  final double orderTotal;

  static Future<void> show(BuildContext context, {required double orderTotal}) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => ChangeCalculatorDialog(orderTotal: orderTotal),
    );
  }

  @override
  State<ChangeCalculatorDialog> createState() => _ChangeCalculatorDialogState();
}

class _ChangeCalculatorDialogState extends State<ChangeCalculatorDialog> {
  late final TextEditingController _cashController;
  double _cashReceived = 0.0;

  @override
  void initState() {
    super.initState();
    // Default preset: closest 100 or 50 above total
    final defaultAmount = (widget.orderTotal / 50).ceil() * 50.0;
    _cashReceived = defaultAmount > 0 ? defaultAmount : widget.orderTotal;
    _cashController = TextEditingController(
      text: _cashReceived > 0 ? _cashReceived.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  void _setPreset(double amount) {
    setState(() {
      _cashReceived = amount;
      _cashController.text = amount.toStringAsFixed(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final result = DriverQuickActionService.calculateChange(
      orderTotal: widget.orderTotal,
      cashReceived: _cashReceived,
    );

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: const Icon(
              Icons.calculate_rounded,
              color: Color(0xFF10B981),
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Text(
            'حاسبة الباقي السريعة',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Total Header
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('مطلوب من العميل:'),
                  Text(
                    Formatters.formatCurrency(widget.orderTotal),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Cash Received Input
            Text(
              'المبلغ المدفوع من العميل:',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              controller: _cashController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.payments_outlined),
                suffixText: 'ج.م',
              ),
              onChanged: (val) {
                setState(() {
                  _cashReceived = double.tryParse(val.trim()) ?? 0.0;
                });
              },
            ),
            const SizedBox(height: AppSpacing.sm),

            // Quick Presets (100, 200, 500, 1000)
            Wrap(
              spacing: 6,
              children: [
                if (widget.orderTotal <= 100)
                  _buildPresetChip(100),
                if (widget.orderTotal <= 200)
                  _buildPresetChip(200),
                _buildPresetChip(300),
                _buildPresetChip(500),
                _buildPresetChip(1000),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Result Display Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: result.isInsufficient
                    ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                    : (result.isExact
                        ? const Color(0xFF3B82F6).withValues(alpha: 0.12)
                        : const Color(0xFF10B981).withValues(alpha: 0.12)),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: result.isInsufficient
                      ? const Color(0xFFEF4444)
                      : (result.isExact
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFF10B981)),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    result.isInsufficient
                        ? 'المبلغ غير كافٍ! ينقص العميل:'
                        : (result.isExact
                            ? 'المبلغ مضبوط بالتمام (بدون باقي)'
                            : 'المتبقي ترجعه للعميل فكة:'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: result.isInsufficient
                          ? const Color(0xFFEF4444)
                          : (result.isExact
                              ? const Color(0xFF3B82F6)
                              : const Color(0xFF10B981)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    result.isInsufficient
                        ? Formatters.formatCurrency(result.shortfall)
                        : Formatters.formatCurrency(result.changeDue),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: result.isInsufficient
                          ? const Color(0xFFEF4444)
                          : (result.isExact
                              ? const Color(0xFF3B82F6)
                              : const Color(0xFF10B981)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('تم'),
        ),
      ],
    );
  }

  Widget _buildPresetChip(double amount) {
    final isSelected = _cashReceived == amount;
    return ActionChip(
      label: Text('${amount.toStringAsFixed(0)} ج.م'),
      backgroundColor: isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      onPressed: () => _setPreset(amount),
    );
  }
}
