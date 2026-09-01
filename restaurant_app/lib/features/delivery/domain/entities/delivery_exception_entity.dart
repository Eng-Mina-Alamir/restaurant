/// Reasons for delivery exceptions and failures in the field
enum DeliveryExceptionReason {
  customerUnreachable('العميل لا يجيب على الهاتف'),
  wrongAddress('العنوان غير صحيح أو غير موجود'),
  customerRefused('العميل رفض استلام الطلب'),
  damagedInTransit('تلف الطلب أثناء القيادة'),
  cancelledByCustomer('تم الإلغاء من العميل بعد وصول السائق'),
  other('سبب آخر');

  final String labelAr;
  const DeliveryExceptionReason(this.labelAr);
}

/// Delivery Exception & Return to Kitchen Log Record
class DeliveryExceptionEntity {
  const DeliveryExceptionEntity({
    required this.id,
    required this.assignmentId,
    required this.orderId,
    required this.driverId,
    required this.driverName,
    required this.reason,
    required this.callAttemptsCount,
    required this.timestamp,
    this.notes = '',
    this.returnedToKitchen = true,
  });

  final String id;
  final String assignmentId;
  final String orderId;
  final String driverId;
  final String driverName;
  final DeliveryExceptionReason reason;
  final int callAttemptsCount;
  final DateTime timestamp;
  final String notes;
  final bool returnedToKitchen;

  Map<String, dynamic> toJson() => {
        'id': id,
        'assignment_id': assignmentId,
        'order_id': orderId,
        'driver_id': driverId,
        'driver_name': driverName,
        'reason': reason.name,
        'call_attempts': callAttemptsCount,
        'timestamp': timestamp.toIso8601String(),
        'notes': notes,
        'returned_to_kitchen': returnedToKitchen,
      };

  factory DeliveryExceptionEntity.fromJson(Map<String, dynamic> json) {
    return DeliveryExceptionEntity(
      id: json['id'] as String? ?? '',
      assignmentId: json['assignment_id'] as String? ?? '',
      orderId: json['order_id'] as String? ?? '',
      driverId: json['driver_id'] as String? ?? '',
      driverName: json['driver_name'] as String? ?? '',
      reason: DeliveryExceptionReason.values.firstWhere(
        (r) => r.name == json['reason'],
        orElse: () => DeliveryExceptionReason.other,
      ),
      callAttemptsCount: (json['call_attempts'] as num?)?.toInt() ?? 1,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      notes: json['notes'] as String? ?? '',
      returnedToKitchen: json['returned_to_kitchen'] as bool? ?? true,
    );
  }
}
