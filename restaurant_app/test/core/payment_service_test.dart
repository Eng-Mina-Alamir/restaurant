import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/payment/mock_payment_gateway.dart';
import 'package:restaurant_app/core/payment/payment_service.dart';

void main() {
  group('PaymentService and MockPaymentGateway', () {
    test('successfully processes digital and cash payments', () async {
      final gateway = MockPaymentGateway();
      final service = PaymentService(gateway);

      final cardResult = await service.payForOrder(
        orderId: 'ORD-101',
        amount: 85.50,
        method: PaymentMethod.card,
      );

      expect(cardResult.isSuccess, isTrue);
      expect(cardResult.transactionId, isNotNull);
      expect(cardResult.transactionId, startsWith('TXN-CARD'));
      expect(service.transactions.length, 1);
      expect(service.transactions.first.orderId, 'ORD-101');

      final cashResult = await service.payForOrder(
        orderId: 'ORD-102',
        amount: 40.0,
        method: PaymentMethod.cash,
      );

      expect(cashResult.isSuccess, isTrue);
      expect(cashResult.transactionId, startsWith('CASH-'));
      expect(service.transactions.length, 2);
    });

    test('handles payment failure scenarios gracefully', () async {
      final gateway = MockPaymentGateway(
        shouldFail: true,
        failureReason: 'رصيد البطاقة غير كافٍ',
      );
      final service = PaymentService(gateway);

      final result = await service.payForOrder(
        orderId: 'ORD-103',
        amount: 150.0,
        method: PaymentMethod.card,
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, 'رصيد البطاقة غير كافٍ');
      expect(service.transactions, isEmpty);
    });

    test('rejects negative or zero amount payments', () async {
      final gateway = MockPaymentGateway();
      final service = PaymentService(gateway);

      final result = await service.payForOrder(
        orderId: 'ORD-104',
        amount: 0,
        method: PaymentMethod.card,
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('أكبر من الصفر'));
    });

    test('refund processes successfully', () async {
      final gateway = MockPaymentGateway();
      final service = PaymentService(gateway);

      final refundResult = await service.refund(
        transactionId: 'TXN-CARD-12345',
        amount: 50.0,
      );

      expect(refundResult.isSuccess, isTrue);
      expect(refundResult.refundId, startsWith('REF-'));
      expect(refundResult.amount, 50.0);
    });
  });
}
