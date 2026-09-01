import '../../../../core/domain/enums.dart';

/// A recorded refund / return transaction on an order.
class OrderRefundRecord {
  const OrderRefundRecord({
    required this.id,
    required this.originalOrderId,
    required this.refundAmount,
    required this.refundMethod,
    required this.reason,
    required this.refundedAt,
    this.refundedItemNames = const [],
    this.managerPin,
    this.cashierId,
  });

  final String id;
  final String originalOrderId;
  final double refundAmount;
  final PaymentMethod refundMethod;
  final String reason;
  final DateTime refundedAt;
  final List<String> refundedItemNames;
  final String? managerPin;
  final String? cashierId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'originalOrderId': originalOrderId,
    'refundAmount': refundAmount,
    'refundMethod': refundMethod.name,
    'reason': reason,
    'refundedAt': refundedAt.toIso8601String(),
    'refundedItemNames': refundedItemNames,
    'managerPin': managerPin,
    'cashierId': cashierId,
  };
}
