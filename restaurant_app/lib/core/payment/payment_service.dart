import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/enums.dart';
import '../utils/logger.dart';
import 'mock_payment_gateway.dart';
import 'payment_gateway.dart';

/// Stored record of a processed payment transaction.
class PaymentTransactionRecord {
  const PaymentTransactionRecord({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.method,
    required this.isSuccess,
    required this.authorizationCode,
    required this.timestamp,
  });

  final String id;
  final String orderId;
  final double amount;
  final PaymentMethod method;
  final bool isSuccess;
  final String authorizationCode;
  final DateTime timestamp;
}

/// Service managing payment workflows and transaction auditing.
class PaymentService {
  PaymentService([PaymentGateway? gateway])
      : _gateway = gateway ?? MockPaymentGateway();

  final PaymentGateway _gateway;
  final List<PaymentTransactionRecord> _transactions = [];

  List<PaymentTransactionRecord> get transactions =>
      List.unmodifiable(_transactions);

  /// Executes payment for an order.
  Future<PaymentResult> payForOrder({
    required String orderId,
    required double amount,
    required PaymentMethod method,
    String? phone,
  }) async {
    AppLogger.info('Processing payment of $amount SAR for order $orderId via ${method.name}');

    final request = PaymentRequest(
      orderId: orderId,
      amount: amount,
      method: method,
      customerPhone: phone,
    );

    final result = await _gateway.processPayment(request);

    if (result.isSuccess) {
      _transactions.add(
        PaymentTransactionRecord(
          id: result.transactionId ?? 'TXN-${DateTime.now().millisecondsSinceEpoch}',
          orderId: orderId,
          amount: amount,
          method: method,
          isSuccess: true,
          authorizationCode: result.authorizationCode ?? '',
          timestamp: result.timestamp,
        ),
      );
      AppLogger.info('Payment succeeded: ${result.transactionId}');
    } else {
      AppLogger.warning('Payment failed: ${result.errorMessage}');
    }

    return result;
  }

  /// Refunds a transaction.
  Future<RefundResult> refund({
    required String transactionId,
    required double amount,
  }) {
    AppLogger.info('Refunding $amount SAR for transaction $transactionId');
    return _gateway.refund(transactionId, amount);
  }
}

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService();
});
