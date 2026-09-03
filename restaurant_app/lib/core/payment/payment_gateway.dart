import '../domain/enums.dart';

/// Request payload for processing a payment transaction.
class PaymentRequest {
  const PaymentRequest({
    required this.orderId,
    required this.amount,
    this.currency = 'EGP',
    required this.method,
    this.customerPhone,
    this.metadata = const {},
  });

  final String orderId;
  final double amount;
  final String currency;
  final PaymentMethod method;
  final String? customerPhone;
  final Map<String, dynamic> metadata;
}

/// Result returned from a payment transaction attempt.
class PaymentResult {
  const PaymentResult._({
    required this.isSuccess,
    this.transactionId,
    this.authorizationCode,
    this.errorMessage,
    required this.timestamp,
  });

  factory PaymentResult.success({
    required String transactionId,
    String? authorizationCode,
  }) {
    return PaymentResult._(
      isSuccess: true,
      transactionId: transactionId,
      authorizationCode:
          authorizationCode ??
          'AUTH-${DateTime.now().millisecondsSinceEpoch % 100000}',
      timestamp: DateTime.now(),
    );
  }

  factory PaymentResult.failure(String errorMessage) {
    return PaymentResult._(
      isSuccess: false,
      errorMessage: errorMessage,
      timestamp: DateTime.now(),
    );
  }

  final bool isSuccess;
  final String? transactionId;
  final String? authorizationCode;
  final String? errorMessage;
  final DateTime timestamp;
}

/// Result returned from a refund request.
class RefundResult {
  const RefundResult._({
    required this.isSuccess,
    this.refundId,
    this.amount,
    this.errorMessage,
  });

  factory RefundResult.success({
    required String refundId,
    required double amount,
  }) {
    return RefundResult._(isSuccess: true, refundId: refundId, amount: amount);
  }

  factory RefundResult.failure(String errorMessage) {
    return RefundResult._(isSuccess: false, errorMessage: errorMessage);
  }

  final bool isSuccess;
  final String? refundId;
  final double? amount;
  final String? errorMessage;
}

/// Abstract contract for payment gateway implementations (Stripe, Tap, PayTabs, Mock).
abstract interface class PaymentGateway {
  String get name;
  Future<PaymentResult> processPayment(PaymentRequest request);
  Future<RefundResult> refund(String transactionId, double amount);
}
