import 'package:flutter/foundation.dart';

/// Type of assistance requested by a customer at a table.
enum TableServiceType {
  callWaiter,
  requestBill,
  cleanTable,
  other;

  String get labelAr {
    switch (this) {
      case TableServiceType.callWaiter:
        return 'استدعاء النادل';
      case TableServiceType.requestBill:
        return 'طلب الفاتورة والحساب';
      case TableServiceType.cleanTable:
        return 'طلب تنظيف الطاولة';
      case TableServiceType.other:
        return 'مساعدة أخرى';
    }
  }

  static TableServiceType fromName(String? name) {
    switch (name?.toLowerCase()) {
      case 'callwaiter':
      case 'call_waiter':
        return TableServiceType.callWaiter;
      case 'requestbill':
      case 'request_bill':
        return TableServiceType.requestBill;
      case 'cleantable':
      case 'clean_table':
        return TableServiceType.cleanTable;
      default:
        return TableServiceType.other;
    }
  }
}

/// Represents an active or historical assistance request initiated by a customer
/// at a specific dining table.
@immutable
class TableServiceRequest {
  const TableServiceRequest({
    required this.id,
    required this.tableId,
    required this.tableNumber,
    required this.type,
    this.note,
    required this.requestedAt,
    this.isHandled = false,
    this.handledAt,
    this.handledByWaiterId,
  });

  final String id;
  final String tableId;
  final int tableNumber;
  final TableServiceType type;
  final String? note;
  final DateTime requestedAt;
  final bool isHandled;
  final DateTime? handledAt;
  final String? handledByWaiterId;

  TableServiceRequest copyWith({
    String? id,
    String? tableId,
    int? tableNumber,
    TableServiceType? type,
    String? note,
    DateTime? requestedAt,
    bool? isHandled,
    DateTime? handledAt,
    String? handledByWaiterId,
  }) {
    return TableServiceRequest(
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      tableNumber: tableNumber ?? this.tableNumber,
      type: type ?? this.type,
      note: note ?? this.note,
      requestedAt: requestedAt ?? this.requestedAt,
      isHandled: isHandled ?? this.isHandled,
      handledAt: handledAt ?? this.handledAt,
      handledByWaiterId: handledByWaiterId ?? this.handledByWaiterId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'table_id': tableId,
      'table_number': tableNumber,
      'type': type.name,
      'note': note,
      'requested_at': requestedAt.toIso8601String(),
      'is_handled': isHandled,
      'handled_at': handledAt?.toIso8601String(),
      'handled_by_waiter_id': handledByWaiterId,
    };
  }

  factory TableServiceRequest.fromJson(Map<String, dynamic> json) {
    return TableServiceRequest(
      id: json['id'] as String? ?? 'REQ-${DateTime.now().millisecondsSinceEpoch}',
      tableId: json['table_id'] as String? ?? json['tableId'] as String? ?? '',
      tableNumber: (json['table_number'] ?? json['tableNumber'] as num?)?.toInt() ?? 0,
      type: TableServiceType.fromName(json['type'] as String?),
      note: json['note'] as String?,
      requestedAt: json['requested_at'] != null
          ? DateTime.tryParse(json['requested_at'] as String) ?? DateTime.now()
          : (json['requestedAt'] != null
              ? DateTime.tryParse(json['requestedAt'] as String) ?? DateTime.now()
              : DateTime.now()),
      isHandled: json['is_handled'] as bool? ?? json['isHandled'] as bool? ?? false,
      handledAt: json['handled_at'] != null
          ? DateTime.tryParse(json['handled_at'] as String)
          : (json['handledAt'] != null
              ? DateTime.tryParse(json['handledAt'] as String)
              : null),
      handledByWaiterId: json['handled_by_waiter_id'] as String? ??
          json['handledByWaiterId'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TableServiceRequest && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
