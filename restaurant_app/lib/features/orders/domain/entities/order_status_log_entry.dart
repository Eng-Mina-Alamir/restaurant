import '../../../../core/domain/enums.dart';

/// Immutable audit record for an order status transition.
///
/// Persisted to the Supabase `order_status_log` table on reverts; the local
/// repositories keep these entries in memory so tests and offline sessions
/// can still inspect the audit trail.
class OrderStatusLogEntry {
  const OrderStatusLogEntry({
    required this.orderId,
    required this.fromStatus,
    required this.toStatus,
    required this.actorId,
    this.reason,
    this.isRevert = false,
    required this.createdAt,
  });

  final String orderId;
  final OrderStatus fromStatus;
  final OrderStatus toStatus;

  /// Authenticated staff id that performed the transition.
  final String actorId;

  /// Optional operator-supplied justification (reverts only).
  final String? reason;

  /// True when [toStatus] is a guarded backward move of [fromStatus].
  final bool isRevert;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'orderId': orderId,
    'fromStatus': fromStatus.name,
    'toStatus': toStatus.name,
    'actorId': actorId,
    if (reason != null) 'reason': reason,
    'isRevert': isRevert,
    'createdAt': createdAt.toIso8601String(),
  };
}
