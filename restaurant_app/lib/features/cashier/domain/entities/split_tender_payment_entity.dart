import '../../../../core/domain/enums.dart';

/// A single payment share in a multi-tender transaction (e.g. 200 EGP Cash + 300 EGP Card).
class SplitTenderShare {
  const SplitTenderShare({
    required this.id,
    required this.method,
    required this.amount,
    this.referenceNumber,
    this.tenderedAmount,
    this.changeDue = 0.0,
    required this.paidAt,
  });

  final String id;
  final PaymentMethod method;
  final double amount;
  final String? referenceNumber;
  final double? tenderedAmount;
  final double changeDue;
  final DateTime paidAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'method': method.name,
    'amount': amount,
    'referenceNumber': referenceNumber,
    'tenderedAmount': tenderedAmount,
    'changeDue': changeDue,
    'paidAt': paidAt.toIso8601String(),
  };
}

/// The accumulated result of a multi-tender transaction for an order.
class SplitTenderResult {
  const SplitTenderResult({
    required this.orderId,
    required this.totalAmountDue,
    required this.payments,
  });

  final String orderId;
  final double totalAmountDue;
  final List<SplitTenderShare> payments;

  double get totalPaid => payments.fold<double>(0.0, (acc, p) => acc + p.amount);

  double get remainingBalance => (totalAmountDue - totalPaid).clamp(0.0, totalAmountDue);

  bool get isFullyPaid => totalPaid >= (totalAmountDue - 0.05);
}
