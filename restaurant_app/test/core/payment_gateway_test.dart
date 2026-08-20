import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/payment/mock_payment_gateway.dart';
import 'package:restaurant_app/core/payment/payment_gateway.dart';

void main() {
  group('PaymentRequest, PaymentResult & RefundResult Tests', () {
    test('PaymentRequest holds provided fields', () {
      const req = PaymentRequest(
        orderId: 'ORD-101',
        amount: 85.5,
        method: PaymentMethod.card,
        customerPhone: '0501234567',
        metadata: {'promo': 'SUMMER10'},
      );

      expect(req.orderId, 'ORD-101');
      expect(req.amount, 85.5);
      expect(req.currency, 'SAR');
      expect(req.method, PaymentMethod.card);
      expect(req.customerPhone, '0501234567');
      expect(req.metadata['promo'], 'SUMMER10');
    });

    test('PaymentResult success and failure factories', () {
      final success = PaymentResult.success(
        transactionId: 'TXN-123',
        authorizationCode: 'AUTH-999',
      );
      expect(success.isSuccess, isTrue);
      expect(success.transactionId, 'TXN-123');
      expect(success.authorizationCode, 'AUTH-999');
      expect(success.errorMessage, isNull);

      final failure = PaymentResult.failure('Card declined');
      expect(failure.isSuccess, isFalse);
      expect(failure.errorMessage, 'Card declined');
      expect(failure.transactionId, isNull);
    });

    test('RefundResult success and failure factories', () {
      final success = RefundResult.success(refundId: 'REF-001', amount: 50.0);
      expect(success.isSuccess, isTrue);
      expect(success.refundId, 'REF-001');
      expect(success.amount, 50.0);

      final failure = RefundResult.failure('Refund expired');
      expect(failure.isSuccess, isFalse);
      expect(failure.errorMessage, 'Refund expired');
    });
  });

  group('MockPaymentGateway Tests', () {
    late MockPaymentGateway gateway;

    setUp(() {
      gateway = MockPaymentGateway();
    });

    test('gateway properties and name', () {
      expect(gateway.name, 'MockSandboxGateway');
      expect(gateway.shouldFail, isFalse);
    });

    test('fails if amount <= 0', () async {
      const req = PaymentRequest(
        orderId: 'ORD-0',
        amount: 0,
        method: PaymentMethod.card,
      );

      final res = await gateway.processPayment(req);
      expect(res.isSuccess, isFalse);
      expect(res.errorMessage, contains('أكبر من الصفر'));
    });

    test('cash payment returns immediate approval', () async {
      const req = PaymentRequest(
        orderId: 'ORD-CASH',
        amount: 50.0,
        method: PaymentMethod.cash,
      );

      final res = await gateway.processPayment(req);
      expect(res.isSuccess, isTrue);
      expect(res.authorizationCode, 'CASH-OK');
      expect(res.transactionId, contains('CASH-'));
    });

    test('card and digital payments succeed in normal mode', () async {
      const reqCard = PaymentRequest(
        orderId: 'ORD-CARD',
        amount: 120.0,
        method: PaymentMethod.card,
      );

      final resCard = await gateway.processPayment(reqCard);
      expect(resCard.isSuccess, isTrue);
      expect(resCard.transactionId, contains('TXN-CARD'));
      expect(resCard.authorizationCode, contains('AUTH-'));

      const reqWallet = PaymentRequest(
        orderId: 'ORD-WALLET',
        amount: 45.0,
        method: PaymentMethod.wallet,
      );
      final resWallet = await gateway.processPayment(reqWallet);
      expect(resWallet.isSuccess, isTrue);
      expect(resWallet.transactionId, contains('TXN-WALLET'));
    });

    test('fails when shouldFail is true', () async {
      gateway.shouldFail = true;
      gateway.failureReason = 'Custom error';

      const req = PaymentRequest(
        orderId: 'ORD-FAIL',
        amount: 100.0,
        method: PaymentMethod.card,
      );

      final res = await gateway.processPayment(req);
      expect(res.isSuccess, isFalse);
      expect(res.errorMessage, 'Custom error');
    });

    test('refund returns success when shouldFail is false', () async {
      final res = await gateway.refund('TXN-123', 50.0);
      expect(res.isSuccess, isTrue);
      expect(res.refundId, contains('REF-'));
      expect(res.amount, 50.0);
    });

    test('refund returns failure when shouldFail is true', () async {
      gateway.shouldFail = true;
      final res = await gateway.refund('TXN-123', 50.0);
      expect(res.isSuccess, isFalse);
      expect(res.errorMessage, 'تعذر استرداد المبلغ');
    });
  });
}
