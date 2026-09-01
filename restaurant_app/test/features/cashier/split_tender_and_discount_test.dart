import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/cashier/domain/entities/cashier_discount_entity.dart';
import 'package:restaurant_app/features/cashier/domain/entities/loyalty_customer_entity.dart';
import 'package:restaurant_app/features/cashier/domain/entities/split_tender_payment_entity.dart';
import 'package:restaurant_app/features/cashier/domain/services/split_tender_service.dart';
import 'package:restaurant_app/features/cashier/presentation/controllers/cashier_pos_controller.dart';

void main() {
  group('Cashier Discount & Loyalty Calculations', () {
    test('CashierDiscount calculates percentage, fixed amount, and comps correctly', () {
      const disc10 = CashierDiscount(
        id: 'd1',
        nameAr: 'خصم 10%',
        type: DiscountType.percentage,
        value: 10.0,
      );
      expect(disc10.calculateDiscountAmount(400.0), equals(40.0));

      const fixed50 = CashierDiscount(
        id: 'd2',
        nameAr: 'خصم 50 ج.م',
        type: DiscountType.fixedAmount,
        value: 50.0,
      );
      expect(fixed50.calculateDiscountAmount(400.0), equals(50.0));

      const comp = CashierDiscount(
        id: 'd3',
        nameAr: 'ضيافة 100%',
        type: DiscountType.complimentary,
        value: 100.0,
      );
      expect(comp.calculateDiscountAmount(400.0), equals(400.0));
    });

    test('CashierPOSController manages discounts and loyalty points redemption', () {
      final controller = CashierPOSController();

      // Apply 10% discount on 500 EGP
      controller.applyDiscount(
        const CashierDiscount(
          id: 'd1',
          nameAr: 'خصم 10%',
          type: DiscountType.percentage,
          value: 10.0,
        ),
      );

      // Link loyalty customer
      final customer = LoyaltyCustomer.demoCustomers.first; // 450 points = 45 EGP
      controller.linkCustomer(customer);
      controller.redeemCustomerPoints(200); // 20 EGP

      // Total discount on 500 = (500 * 10%) + 20 = 50 + 20 = 70 EGP
      final totalDisc = controller.state.calculateTotalDiscount(500.0);
      expect(totalDisc, equals(70.0));

      // Reset
      controller.reset();
      expect(controller.state.selectedDiscount, isNull);
      expect(controller.state.linkedLoyaltyCustomer, isNull);
      expect(controller.state.calculateTotalDiscount(500.0), equals(0.0));
    });
  });

  group('SplitTenderService', () {
    test('SplitTenderService tracks multi-payments and checks settlement', () {
      var result = const SplitTenderResult(
        orderId: 'ORD-123',
        totalAmountDue: 650.0,
        payments: [],
      );

      expect(result.remainingBalance, equals(650.0));
      expect(result.isFullyPaid, isFalse);

      // 1. Pay 300 in cash
      result = SplitTenderService.addPaymentShare(
        currentResult: result,
        method: PaymentMethod.cash,
        amount: 300.0,
      );

      expect(result.totalPaid, equals(300.0));
      expect(result.remainingBalance, equals(350.0));
      expect(result.isFullyPaid, isFalse);

      // 2. Pay remaining 350 on card
      result = SplitTenderService.addPaymentShare(
        currentResult: result,
        method: PaymentMethod.card,
        amount: 350.0,
        referenceNumber: 'TX-98765',
      );

      expect(result.totalPaid, equals(650.0));
      expect(result.remainingBalance, equals(0.0));
      expect(result.isFullyPaid, isTrue);
      expect(result.payments.length, equals(2));
    });
  });
}
