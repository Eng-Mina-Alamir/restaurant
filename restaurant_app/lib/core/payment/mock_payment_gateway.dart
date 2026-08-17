import 'dart:async';

import '../domain/enums.dart';
import 'payment_gateway.dart';

/// Sandbox / mock payment gateway for reliable offline and demo transactions.
class MockPaymentGateway implements PaymentGateway {
  MockPaymentGateway({
    this.simulatedDelay = Duration.zero,
    this.shouldFail = false,
    this.failureReason = 'فشلت عملية الدفع، يرجى التحقق من بيانات البطاقة',
  });

  final Duration simulatedDelay;
  bool shouldFail;
  String failureReason;

  @override
  String get name => 'MockSandboxGateway';

  @override
  Future<PaymentResult> processPayment(PaymentRequest request) async {
    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
    }

    if (request.amount <= 0) {
      return PaymentResult.failure('مبلغ الدفع يجب أن يكون أكبر من الصفر');
    }

    if (shouldFail) {
      return PaymentResult.failure(failureReason);
    }

    // Cash is always instantly approved
    if (request.method == PaymentMethod.cash) {
      return PaymentResult.success(
        transactionId: 'CASH-${DateTime.now().millisecondsSinceEpoch}',
        authorizationCode: 'CASH-OK',
      );
    }

    // Digital card/Apple pay simulation
    final txnId = 'TXN-${request.method.name.toUpperCase()}-${DateTime.now().millisecondsSinceEpoch}';
    return PaymentResult.success(
      transactionId: txnId,
      authorizationCode: 'AUTH-${(DateTime.now().millisecondsSinceEpoch % 89999) + 10000}',
    );
  }

  @override
  Future<RefundResult> refund(String transactionId, double amount) async {
    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
    }

    if (shouldFail) {
      return RefundResult.failure('تعذر استرداد المبلغ');
    }

    return RefundResult.success(
      refundId: 'REF-${DateTime.now().millisecondsSinceEpoch}',
      amount: amount,
    );
  }
}
