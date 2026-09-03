import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/repositories/delivery_pin_repository.dart';
import '../../domain/services/delivery_pin_service.dart';

class ProofOfDeliveryResult {
  const ProofOfDeliveryResult({
    required this.confirmed,
    required this.otpCode,
    required this.tipAmount,
    this.notes = '',
    this.manualOverride = false,
  });

  final bool confirmed;
  final String otpCode;
  final double tipAmount;
  final String notes;
  final bool manualOverride;
}

/// Dialog prompting driver for the customer verification code (or QR scan)
/// before marking delivered.
///
/// The expected code is the per-order RANDOM code from
/// [DeliveryPinRepository] (stable per order, random across orders) — never
/// the legacy deterministic PIN and never a universal bypass code. Pass
/// [expectedOtp] only in tests; production callers leave it null so the
/// dialog fetches the server code itself.
class ProofOfDeliveryDialog extends StatefulWidget {
  const ProofOfDeliveryDialog({
    super.key,
    required this.orderId,
    required this.isCashOnDelivery,
    required this.amountDue,
    this.expectedOtp,
    this.pinRepository,
  });

  final String orderId;
  final bool isCashOnDelivery;
  final double amountDue;

  /// Test-only override. When null the dialog resolves the code via
  /// [pinRepository] (or shows a fetch error when no repo is wired).
  final String? expectedOtp;
  final DeliveryPinRepository? pinRepository;

  static Future<ProofOfDeliveryResult?> show(
    BuildContext context, {
    required String orderId,
    required bool isCashOnDelivery,
    required double amountDue,
    String? expectedOtp,
    DeliveryPinRepository? pinRepository,
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
            pinRepository: pinRepository,
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
  String? _resolvedOtp;
  bool _loadingPin = false;
  String? _pinLoadError;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.expectedOtp != null) {
      _resolvedOtp = widget.expectedOtp;
    } else if (widget.pinRepository != null) {
      _fetchPin();
    } else {
      _pinLoadError = 'تعذر تجهيز كود التحقق (لا يوجد مخزن أكواد)';
    }
  }

  Future<void> _fetchPin() async {
    setState(() {
      _loadingPin = true;
      _pinLoadError = null;
    });
    final result = await widget.pinRepository!.ensurePin(widget.orderId);
    if (!mounted) return;
    result.when(
      onLeft: (_) => setState(() {
        _loadingPin = false;
        _pinLoadError = 'تعذر جلب كود التحقق — تحقق من الاتصال وحاول مجدداً';
      }),
      onRight: (pin) => setState(() {
        _loadingPin = false;
        _resolvedOtp = pin;
      }),
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    _tipController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final enteredOtp = DeliveryPinService.extractCode(_otpController.text);
    if (_overrideOtp) {
      if (_notesController.text.trim().isEmpty) {
        setState(
          () => _errorMessage = 'التسليم اليدوي يتطلب كتابة ملاحظة (مثال: استلم الحارس)',
        );
        return;
      }
    } else {
      if (enteredOtp.isEmpty) {
        setState(() => _errorMessage = 'يرجى إدخال كود الاستلام من العميل');
        return;
      }
      if (!DeliveryPinService.isValidFormat(enteredOtp)) {
        setState(() => _errorMessage = 'صيغة الكود غير صحيحة');
        return;
      }
      setState(() {
        _submitting = true;
        _errorMessage = null;
      });
      try {
        final ok = await _verifyCode(enteredOtp);
        if (!mounted) return;
        if (!ok) {
          setState(() {
            _submitting = false;
            _errorMessage = 'كود الاستلام غير صحيح! تأكد من شاشة العميل';
          });
          return;
        }
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _submitting = false;
          _errorMessage = 'تعذر التحقق من الكود — حاول مجدداً';
        });
        return;
      }
      if (mounted) setState(() => _submitting = false);
    }

    final tip = double.tryParse(_tipController.text.trim()) ?? 0.0;

    if (!mounted) return;
    Navigator.pop(
      context,
      ProofOfDeliveryResult(
        confirmed: true,
        otpCode: _overrideOtp ? '' : enteredOtp,
        tipAmount: tip,
        notes: _notesController.text.trim(),
        manualOverride: _overrideOtp,
      ),
    );
  }

  /// Verifies [entered] against the server code. No universal bypass codes
  /// are accepted — only the exact per-order code passes.
  Future<bool> _verifyCode(String entered) async {
    final repo = widget.pinRepository;
    if (repo != null) {
      final result = await repo.verifyPin(widget.orderId, entered);
      return result.when(onLeft: (_) => false, onRight: (ok) => ok);
    }
    final expected = _resolvedOtp ?? widget.expectedOtp;
    if (expected == null || expected.isEmpty) return false;
    return entered == expected;
  }

  void _openQrScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        height: 440,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'مسح رمز QR للتأكيد',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(sheetContext),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'وجّه الكاميرا نحو رمز QR الظاهر في شاشة هاتف العميل',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: MobileScanner(
                  onDetect: (capture) {
                    final barcode = capture.barcodes.firstOrNull;
                    if (barcode == null) return;
                    final raw = barcode.rawValue?.trim() ?? '';
                    if (raw.isNotEmpty) {
                      final scannedPin = DeliveryPinService.extractCode(raw);
                      if (scannedPin.isEmpty) return;
                      _otpController.text = scannedPin;
                      Navigator.pop(sheetContext);
                      _submit();
                    }
                  },
                ),
              ),
            ),
          ],
        ),
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

              if (_loadingPin) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: CircularProgressIndicator(),
                  ),
                ),
                const Center(
                  child: Text('جارٍ تجهيز كود التحقق...', style: TextStyle(fontSize: 12)),
                ),
              ] else if (_pinLoadError != null && !_overrideOtp) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(_pinLoadError!, style: const TextStyle(fontSize: 12)),
                      ),
                      TextButton(
                        onPressed: _fetchPin,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              ] else if (!_overrideOtp) ...[
                Text(
                  'كود تأكيد الاستلام:',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'اطلب كود الاستلام الظاهر في تطبيق العميل أو امسح رمز الـ QR من شاشته',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 10.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          letterSpacing: 8,
                          fontWeight: FontWeight.w900,
                        ),
                        maxLength: 6,
                        decoration: InputDecoration(
                          hintText: '------',
                          errorText: _errorMessage,
                          border: const OutlineInputBorder(),
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton.filledTonal(
                      tooltip: 'مسح رمز QR من هاتف العميل بالكاميرا',
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 26),
                      onPressed: _openQrScanner,
                    ),
                  ],
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
                          'التسليم اليدوي للحالات الاستثنائية فقط ويتطلب ملاحظة — يُسجَّل في سجل الطلب.',
                          style: TextStyle(fontSize: 11.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'ملاحظة التسليم (إلزامية — مثلاً: استلم الحارس)',
                    errorText: _errorMessage,
                    border: const OutlineInputBorder(),
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
                      ? 'الرجوع لإدخال الكود'
                      : 'العميل لا يملك الكود؟ (تسليم يدوي استثنائي)',
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
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton.icon(
          onPressed: (_submitting || _loadingPin) ? null : _submit,
          icon: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_circle_outline, size: 18),
          label: const Text('تأكيد واكتمال التسليم'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
          ),
        ),
      ],
    );
  }
}
