import 'package:flutter/material.dart';
import '../../../../core/theme/spacing.dart';

enum ManagerApprovalAction {
  voidOrder('إلغاء طلب مرسل للمطبخ'),
  fullDiscount('تطبيق خصم ضيافة 100% (Complimentary)'),
  openCashDrawer('فتح درج الكاشير يدويًا'),
  priceOverride('تعديل سعر الصنف يدويًا');

  final String titleAr;
  const ManagerApprovalAction(this.titleAr);
}

/// Dialog enforcing Manager PIN Code & Reason tracking for critical cashier actions.
class ManagerApprovalDialog extends StatefulWidget {
  const ManagerApprovalDialog({
    super.key,
    required this.action,
    this.targetDescription,
  });

  final ManagerApprovalAction action;
  final String? targetDescription;

  /// Static helper to prompt approval
  static Future<bool?> show(
    BuildContext context, {
    required ManagerApprovalAction action,
    String? targetDescription,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => ManagerApprovalDialog(
            action: action,
            targetDescription: targetDescription,
          ),
    );
  }

  @override
  State<ManagerApprovalDialog> createState() => _ManagerApprovalDialogState();
}

class _ManagerApprovalDialogState extends State<ManagerApprovalDialog> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  String? _errorMessage;

  // For demonstration / restaurant standard setup: Manager PIN is 1234 or 9999
  static const Set<String> _validManagerPins = {'1234', '9999', '123456'};

  void _verifyAndApprove() {
    final pin = _pinController.text.trim();
    final reason = _reasonController.text.trim();

    if (pin.isEmpty) {
      setState(() => _errorMessage = 'يرجى إدخال الرقم السري للمدير');
      return;
    }

    if (!_validManagerPins.contains(pin)) {
      setState(() => _errorMessage = 'الرقم السري للمدير غير صحيح');
      return;
    }

    if (reason.isEmpty &&
        widget.action != ManagerApprovalAction.openCashDrawer) {
      setState(() => _errorMessage = 'يرجى تدوين سبب الإلغاء/الخصم إجباريًا');
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _pinController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Color(0xFFEF4444),
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'طلب موافقة المدير (Manager PIN)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  widget.action.titleAr,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.targetDescription != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.targetDescription!,
                        style: const TextStyle(fontSize: 11.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            TextFormField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'الرقم السري للمدير (Manager PIN)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline_rounded),
                hintText: 'تجريبي: 1234',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            TextFormField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText:
                    widget.action == ManagerApprovalAction.openCashDrawer
                        ? 'سبب الفتح (اختياري)'
                        : 'سبب الإجراء (إجباري للرقابة)',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.comment_outlined),
                hintText: 'مثلاً: خطأ زبون / استبدال صنف / جودة طعام',
              ),
              maxLines: 2,
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _verifyAndApprove,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
          ),
          child: const Text('تأكيد وموافقة المدير'),
        ),
      ],
    );
  }
}
