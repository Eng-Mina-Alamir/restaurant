import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/utils/financial_calculator.dart';
import 'package:restaurant_app/features/cart/domain/cart_totals.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';

void main() {
  group('Financial Precision & Currency Rounding Unit Tests', () {
    test(
      'roundCurrency prevents standard floating-point representation errors',
      () {
        // 0.1 + 0.2 in standard IEEE-754 double is 0.30000000000000004
        const sum = 0.1 + 0.2;
        expect(sum, isNot(0.3));
        expect(FinancialCalculator.roundCurrency(sum), 0.30);

        // Fractional halalas
        expect(FinancialCalculator.roundCurrency(19.999), 20.00);
        expect(FinancialCalculator.roundCurrency(19.994), 19.99);
        expect(FinancialCalculator.roundCurrency(0.0001), 0.0);
      },
    );

    test(
      'calculateVat computes precise 15% regional tax with correct halala rounding',
      () {
        // 100 SAR -> 15.00 SAR
        expect(FinancialCalculator.calculateVat(100.0), 15.00);

        // 19.99 SAR taxable -> 19.99 * 0.15 = 2.9985 -> rounds to 3.00 SAR
        expect(FinancialCalculator.calculateVat(19.99), 3.00);

        // 33.33 SAR taxable -> 33.33 * 0.15 = 4.9995 -> rounds to 5.00 SAR
        expect(FinancialCalculator.calculateVat(33.33), 5.00);

        // Negative or zero
        expect(FinancialCalculator.calculateVat(0.0), 0.0);
        expect(FinancialCalculator.calculateVat(-50.0), 0.0);
      },
    );

    test(
      'calculatePercentageDiscount clamps accurately and respects max caps',
      () {
        // 20% on 150 SAR = 30.00 SAR
        expect(
          FinancialCalculator.calculatePercentageDiscount(
            subtotal: 150.0,
            percentage: 20.0,
          ),
          30.0,
        );

        // 50% on 200 SAR with max cap 50 SAR -> 50.00 SAR
        expect(
          FinancialCalculator.calculatePercentageDiscount(
            subtotal: 200.0,
            percentage: 50.0,
            maxDiscount: 50.0,
          ),
          50.0,
        );

        // Over 100% discount is clamped to 100% (subtotal)
        expect(
          FinancialCalculator.calculatePercentageDiscount(
            subtotal: 80.0,
            percentage: 150.0,
          ),
          80.0,
        );
      },
    );
  });

  group('Bill Splitting & Remainder Halalas Distribution Tests', () {
    test(
      'splitBillDetailed evenly distributes odd remainder halalas (100 SAR / 3 persons)',
      () {
        final shares = FinancialCalculator.splitBillDetailed(100.00, 3);
        expect(shares.length, 3);
        // 10000 cents / 3 = 3333 cents with 1 remainder cent -> person 1 gets 33.34, others 33.33
        expect(shares[0], 33.34);
        expect(shares[1], 33.33);
        expect(shares[2], 33.33);

        final totalSum = shares.fold<double>(0, (sum, s) => sum + s);
        expect(FinancialCalculator.roundCurrency(totalSum), 100.00);
      },
    );

    test(
      'splitBillDetailed distributes multiple remainder cents (50 SAR / 7 persons)',
      () {
        final shares = FinancialCalculator.splitBillDetailed(50.00, 7);
        expect(shares.length, 7);
        // 5000 cents / 7 = 714 cents (7.14 SAR) with remainder 2 cents -> first 2 get 7.15, rest 7.14
        expect(shares[0], 7.15);
        expect(shares[1], 7.15);
        expect(shares[2], 7.14);
        expect(shares[3], 7.14);
        expect(shares[4], 7.14);
        expect(shares[5], 7.14);
        expect(shares[6], 7.14);

        final totalSum = shares.fold<double>(0, (sum, s) => sum + s);
        expect(FinancialCalculator.roundCurrency(totalSum), 50.00);
      },
    );

    test(
      'splitBillDetailed handles edge cases: 0 persons, 1 person, negative amount',
      () {
        expect(FinancialCalculator.splitBillDetailed(100.0, 0), [100.0]);
        expect(FinancialCalculator.splitBillDetailed(100.0, -2), [100.0]);
        expect(FinancialCalculator.splitBillDetailed(100.0, 1), [100.0]);
        expect(FinancialCalculator.splitBillDetailed(-25.0, 4), [0.0]);
      },
    );
  });

  group('CartTotals & CartController Edge Cases Integration', () {
    const item1 = MenuItem(
      id: 'item-1',
      name: 'شاورما دجاج',
      price: 25.50,
      categoryId: 'cat-1',
      description: 'لذيذة',
      imageUrl: '',
      isAvailable: true,
    );

    const item2 = MenuItem(
      id: 'item-2',
      name: 'عصير برتقال طازج',
      price: 14.50,
      categoryId: 'cat-2',
      description: 'طازج',
      imageUrl: '',
      isAvailable: true,
    );

    test(
      'CartTotals accurately computes subtotal, discount, VAT and total with rounding',
      () {
        final cartItems = [
          const CartItem(menuItem: item1, quantity: 2), // 51.00 SAR
          const CartItem(menuItem: item2, quantity: 1), // 14.50 SAR
        ]; // Raw subtotal = 65.50 SAR

        // Without discount: VAT 15% on 65.50 = 9.825 -> 9.83 SAR. Total = 75.33 SAR
        final totalsNoDiscount = CartTotals.fromItems(cartItems);
        expect(totalsNoDiscount.subtotal, 65.50);
        expect(totalsNoDiscount.taxAmount, 9.83);
        expect(totalsNoDiscount.totalAmount, 75.33);

        // With 15.50 SAR discount: effective subtotal = 50.00 SAR -> VAT = 7.50 SAR -> Total = 57.50 SAR
        final totalsWithDiscount = CartTotals.fromItems(
          cartItems,
          discountAmount: 15.50,
        );
        expect(totalsWithDiscount.subtotal, 65.50);
        expect(totalsWithDiscount.discountAmount, 15.50);
        expect(totalsWithDiscount.taxAmount, 7.50);
        expect(totalsWithDiscount.totalAmount, 57.50);
      },
    );

    test(
      'CartController splitTotalDetailed provides exact per-person breakdown',
      () {
        final controller = CartController();
        controller.addItem(
          const CartItem(menuItem: item1, quantity: 3),
        ); // 76.50 subtotal

        final totals = controller.totals;
        expect(totals.subtotal, 76.50);

        final splitShares = controller.splitTotalDetailed(4);
        expect(splitShares.length, 4);

        final totalSum = splitShares.fold<double>(0, (sum, s) => sum + s);
        expect(FinancialCalculator.roundCurrency(totalSum), totals.totalAmount);
      },
    );
  });
}
