import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/entities/delivery_exception_entity.dart';
import '../../domain/services/driver_quick_action_service.dart';

/// Interactive Customer Unreachable & Exception Handler dialog with 5-minute countdown.
class CustomerUnreachableDialog extends StatefulWidget {
  const CustomerUnreachableDialog({
    super.key,
    required this.orderId,
    required this.customerPhone,
  });

  final String orderId;
  final String? customerPhone;

  static Future<DeliveryExceptionEntity?> show(
    BuildContext context, {
    required String orderId,
    String? customerPhone,
  }) {
    return showDialog<DeliveryExceptionEntity>(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => CustomerUnreachableDialog(
            orderId: orderId,
            customerPhone: customerPhone,
          ),
    );
  }

  @override
  State<CustomerUnreachableDialog> createState() =>
      _CustomerUnreachableDialogState();
}

class _CustomerUnreachableDialogState extends State<CustomerUnreachableDialog> {
  int _secondsRemaining = 300; // 5 minutes standard wait time
  Timer? _timer;
  int _callAttempts = 1;
  DeliveryExceptionReason _selectedReason =
      DeliveryExceptionReason.customerUnreachable;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  void _recordCallAttempt() {
    setState(() => _callAttempts++);
    if (widget.customerPhone != null) {
      final telUri = DriverQuickActionService.getTelUriString(
        widget.customerPhone!,
      );
      DriverQuickActionService.copyToClipboard(widget.customerPhone!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم تسجيل محاولة الاتصال #$_callAttempts ورقم الهاتف بالحافظة ($telUri)',
          ),
        ),
      );
    }
  }

  void _submitReturn() {
    final exception = DeliveryExceptionEntity(
      id: 'exc-${DateTime.now().millisecondsSinceEpoch}',
      assignmentId: 'assign-${widget.orderId}',
      orderId: widget.orderId,
      driverId: 'driver-current',
      driverName: 'الكابتن',
      reason: _selectedReason,
      callAttemptsCount: _callAttempts,
      timestamp: DateTime.now(),
      notes: _notesController.text.trim(),
      returnedToKitchen: true,
    );

    Navigator.pop(context, exception);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    final timeStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
          SizedBox(width: 8),
          Text(
            'تعثر التسليم / العميل لا يجيب',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
              // Countdown Timer Banner
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'مؤقت الانتظار الإلزامي:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          timeStr,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                    OutlinedButton.icon(
                      onPressed: _recordCallAttempt,
                      icon: const Icon(Icons.phone_forwarded, size: 16),
                      label: Text('اتصال ($_callAttempts)'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFEF4444)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              Text(
                'سبب تعثر التسليم:',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              DropdownButtonFormField<DeliveryExceptionReason>(
                initialValue: _selectedReason,
                isExpanded: true,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items:
                    DeliveryExceptionReason.values.map((r) {
                      return DropdownMenuItem(value: r, child: Text(r.labelAr));
                    }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedReason = val);
                },
              ),
              const SizedBox(height: AppSpacing.sm),

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'تفاصيل إضافية عن تعذر التسليم',
                  hintText: 'مثلاً: الهاتف مغلق ودققت الباب دون استجابة',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.sm),

              const Text(
                '⚠️ تأكيد الإلغاء سيعيد الطلب إلى سجل المطبخ ويبرئ ذمتك المالية من تحصيل قيمته.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('الرجوع للطلب'),
        ),
        FilledButton.icon(
          onPressed: _submitReturn,
          icon: const Icon(Icons.undo_rounded, size: 16),
          label: const Text('إرجاع الطلب للمطعم'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
          ),
        ),
      ],
    );
  }
}
