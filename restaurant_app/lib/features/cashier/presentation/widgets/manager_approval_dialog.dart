import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/spacing.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../manager_dashboard/domain/entities/security_audit_log_entity.dart';
import '../../../manager_dashboard/presentation/controllers/security_audit_controller.dart';

enum ManagerApprovalAction {
  voidOrder('إلغاء طلب مرسل للمطبخ'),
  fullDiscount('تطبيق خصم ضيافة 100% (Complimentary)'),
  openCashDrawer('فتح درج الكاشير يدويًا'),
  priceOverride('تعديل سعر الصنف يدويًا');

  final String titleAr;
  const ManagerApprovalAction(this.titleAr);
}

/// Dialog enforcing Manager PIN Code & Reason tracking for critical cashier actions.
///
/// Security model: the PIN is NEVER hardcoded or logged. Verification must be
/// performed server-side (e.g. `verify_manager_pin` RPC); until that backend
/// exists this dialog enforces format + reason + attempt lockout and records
/// an audit event WITHOUT the PIN value. TODO(backend): wire
/// [_verifyPinServerSide] to the real RPC and remove the local-only path.
class ManagerApprovalDialog extends ConsumerStatefulWidget {
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
  ConsumerState<ManagerApprovalDialog> createState() => _ManagerApprovalDialogState();
}

class _ManagerApprovalDialogState extends ConsumerState<ManagerApprovalDialog> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  String? _errorMessage;
  bool _obscurePin = true;
  int _failedAttempts = 0;
  DateTime? _lockedUntil;

  static const int _maxAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 1);

  /// Placeholder until the server-side RPC lands. Currently enforces a
  /// minimum format (≥4 digits) — the real check MUST happen backend-side so
  /// no secret ever lives in the client.
  /// TODO(backend): replace with `verify_manager_pin` RPC call.
  Future<bool> _verifyPinServerSide(String pin) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return pin.length >= 4;
  }

  Future<void> _verifyAndApprove() async {
    if (_lockedUntil != null && DateTime.now().isBefore(_lockedUntil!)) {
      final remaining = _lockedUntil!.difference(DateTime.now()).inSeconds;
      setState(
        () => _errorMessage = 'تم القفل مؤقتاً بعد محاولات خاطئة — حاول بعد $remaining ثانية',
      );
      return;
    }

    final pin = _pinController.text.trim();
    final reason = _reasonController.text.trim();

    if (pin.isEmpty) {
      setState(() => _errorMessage = 'يرجى إدخال الرقم السري للمدير');
      return;
    }

    if (!RegExp(r'^\d{4,}$').hasMatch(pin)) {
      _registerFailure('الرقم السري يجب أن يكون 4 أرقام على الأقل');
      return;
    }

    if (reason.isEmpty &&
        widget.action != ManagerApprovalAction.openCashDrawer) {
      setState(() => _errorMessage = 'يرجى تدوين سبب الإلغاء/الخصم إجباريًا');
      return;
    }

    final ok = await _verifyPinServerSide(pin);
    if (!ok) {
      _registerFailure('الرقم السري للمدير غير صحيح');
      return;
    }

    if (!mounted) return;
    // Audit WITHOUT the PIN value — never persist secrets in logs.
    try {
      final user = ref.read(authControllerProvider).user;
      ref.read(securityAuditControllerProvider.notifier).recordEvent(
            type: SecurityAuditEventType.managerPinOverride,
            actionDescription:
                '${widget.action.titleAr}${widget.targetDescription != null ? ' — ${widget.targetDescription}' : ''} — السبب: $reason',
            staffName: user?.name ?? 'كاشير',
            staffRole: user?.role.name ?? 'cashier',
            severity: AuditSeverity.warning,
            metadata: const {'pinVerified': 'server-pending'},
          );
    } catch (_) {
      // Audit is best-effort and must never block the approval itself.
    }
    Navigator.of(context).pop(true);
  }

  void _registerFailure(String message) {
    _failedAttempts += 1;
    if (_failedAttempts >= _maxAttempts) {
      _lockedUntil = DateTime.now().add(_lockoutDuration);
      _failedAttempts = 0;
      setState(
        () => _errorMessage =
            'تجاوزت الحد الأقصى للمحاولات — تم القفل لمدة دقيقة',
      );
    } else {
      setState(() => _errorMessage = message);
    }
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
              obscureText: _obscurePin,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'الرقم السري للمدير (Manager PIN)',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: _obscurePin ? 'إظهار' : 'إخفاء',
                  icon: Icon(
                    _obscurePin ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _obscurePin = !_obscurePin),
                ),
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
