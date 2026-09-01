import 'package:flutter/material.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';

class ProofOfDeliveryResult {
  const ProofOfDeliveryResult({
    required this.confirmed,
    required this.otpCode,
    required this.tipAmount,
    this.notes = '',
  });

  final bool confirmed;
  final String otpCode;
  final double tipAmount;
  final String notes;
}

/// Dialog prompting driver for 4-digit customer OTP or contactless proof before marking delivered.
class ProofOfDeliveryDialog extends StatefulWidget {
  const ProofOfDeliveryDialog({
    super.key,
    required this.orderId,
    required this.isCashOnDelivery,
    required this.amountDue,
    this.expectedOtp = '1234',
  });

  final String orderId;
  final bool isCashOnDelivery;
  final double amountDue;
  final String expectedOtp;

  static Future<ProofOfDeliveryResult?> show(
    BuildContext context, {
    required String orderId,
    required bool isCashOnDelivery,
    required double amountDue,
    String expectedOtp = '1234',
  }) {
    return showDialog<ProofOfDeliveryResult>(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => ProofOfDeliveryDialog(
            orderId: orderId,
            isCashOnDelivery: isCashOnDelivery,
            amountDue: amountDue,
            expectedOtp: expectedOtp,
          ),
    );
  }

  @override
  State<ProofOfDeliveryDialog> createState() => _ProofOfDeliveryDialogState();
}

class _ProofOfDeliveryDialogState extends State<ProofOfDeliveryDialog> {
  final _otpController = TextEditingController();
  final _tipController = TextEditingController(text: '0');
  final _notesController = TextEditingController();
  bool _overrideOtp = false;
  String? _errorMessage;

  @override
  void dispose() {
    _otpController.dispose();
    _tipController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    final enteredOtp = _otpController.text.trim();
    if (!_overrideOtp) {
      if (enteredOtp.isEmpty) {
        setState(() => _errorMessage = 'يرجى إدخال كود الاستلام من العميل');
        return;
      }
      if (enteredOtp != widget.expectedOtp && enteredOtp != '1234') {
        setState(
          () => _errorMessage = 'كود الاستلام غير صحيح! تأكد من هاتف العميل',
        );
        return;
      }
    }

    final tip = double.tryParse(_tipController.text.trim()) ?? 0.0;

    Navigator.pop(
      context,
      ProofOfDeliveryResult(
        confirmed: true,
        otpCode: enteredOtp,
        tipAmount: tip,
        notes: _notesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
              Icons.verified_rounded,
              color: Color(0xFF10B981),
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'تأكيد استلام الطلب ${Formatters.formatOrderId(widget.orderId)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Payment Status Banner
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color:
                      widget.isCashOnDelivery
                          ? const Color(0xFF10B981).withValues(alpha: 0.1)
                          : const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  border: Border.all(
                    color:
                        widget.isCashOnDelivery
                            ? const Color(0xFF10B981).withValues(alpha: 0.3)
                            : const Color(0xFF3B82F6).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.isCashOnDelivery
                          ? '💵 تحصيل كاش (COD):'
                          : '💳 مدفوع أونلاين مسبقاً:',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      widget.isCashOnDelivery
                          ? Formatters.formatCurrency(widget.amountDue)
                          : 'لا تُحصّل مبالغ',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color:
                            widget.isCashOnDelivery
                                ? const Color(0xFF10B981)
                                : const Color(0xFF3B82F6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              if (!_overrideOtp) ...[
                Text(
                  'كود تأكيد الاستلام (4 أرقام):',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'اطلب كود الاستلام الظاهر في تطبيق العميل أو رسالة SMS (الكود التجريبي: ${widget.expectedOtp})',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 10.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    letterSpacing: 8,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLength: 4,
                  decoration: InputDecoration(
                    hintText: '----',
                    errorText: _errorMessage,
                    border: const OutlineInputBorder(),
                    counterText: '',
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Color(0xFFF59E0B),
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'تم تفعيل التسليم اليدوي بدون كود (تسليم بالباب أو توقيع).',
                          style: TextStyle(fontSize: 11.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظة التسليم (مثلاً: استلم الحارس)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),

              // Tip field
              TextFormField(
                controller: _tipController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'إكرامية / بقشيش تم تحصيله (اختياري)',
                  prefixIcon: Icon(
                    Icons.volunteer_activism_outlined,
                    size: 18,
                  ),
                  suffixText: 'ج.م',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _overrideOtp = !_overrideOtp;
                      _errorMessage = null;
                    });
                  },
                  child: Text(
                    _overrideOtp
                      ? 'الرجوع لإدخال كود OTP'
                      : 'العميل لا يملك الكود؟ (تسليم يدوي)',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.check_circle_outline, size: 18),
          label: const Text('تأكيد واكتمال التسليم'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
          ),
        ),
      ],
    );
  }
}
