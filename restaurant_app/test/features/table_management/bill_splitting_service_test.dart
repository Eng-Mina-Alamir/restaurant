import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_item.dart';
import 'package:restaurant_app/features/table_management/domain/entities/split_bill_entity.dart';
import 'package:restaurant_app/features/table_management/domain/services/bill_splitting_service.dart';

void main() {
  group('BillSplittingService Mathematical Tests', () {
    test('calculateEqualSplit divides total exactly with remainder cents absorption', () {
      final result = BillSplittingService.calculateEqualSplit(
        orderId: 'ORD-100',
        totalBill: 100.0,
        guestCount: 3,
        tipAmount: 0.0,
      );

      expect(result.shares.length, 3);
      expect(result.splitType, SplitBillType.equal);

      final totalOfShares = result.shares.fold<double>(
        0.0,
        (acc, s) => acc + s.totalAmount,
      );
      expect(totalOfShares, 100.0);
      expect(
        BillSplittingService.validateSharesIntegrity(
          result.shares,
          result.originalTotal,
        ),
        isTrue,
      );
    });

    test('calculateEqualSplit includes tip proportionately among guests', () {
      final result = BillSplittingService.calculateEqualSplit(
        orderId: 'ORD-101',
        totalBill: 400.0,
        guestCount: 4,
        tipAmount: 40.0,
      );

      expect(result.shares.length, 4);
      expect(result.originalTotal, 440.0);
      for (final s in result.shares) {
        expect(s.totalAmount, 110.0);
        expect(s.tipAmount, 10.0);
      }
    });

    test('calculateSeatOrItemSplit calculates seat shares with tax and service', () {
      final items = [
        OrderItem(
          menuItem: const MenuItem(
            id: 'm1',
            name: 'كباب مشوي',
            description: 'كباب لحم بلدي',
            price: 150.0,
            categoryId: 'cat-main',
          ),
          quantity: 2,
          addedAt: DateTime.now(),
        ),
        OrderItem(
          menuItem: const MenuItem(
            id: 'm2',
            name: 'أم علي',
            description: 'حلو مصري أصيل',
            price: 50.0,
            categoryId: 'cat-dessert',
          ),
          quantity: 1,
          addedAt: DateTime.now(),
        ),
      ];

      final result = BillSplittingService.calculateSeatOrItemSplit(
        orderId: 'ORD-102',
        orderItems: items,
        totalGuests: 2,
        taxRate: 0.14,
        serviceRate: 0.12,
      );

      expect(result.shares.length, 2);
      expect(result.splitType, SplitBillType.bySeat);
      expect(result.shares.first.subtotal, greaterThan(0));
      expect(
        BillSplittingService.validateSharesIntegrity(
          result.shares,
          result.originalTotal,
        ),
        isTrue,
      );
    });

    test('calculateFromCartItems distributes active cart items for waiter review', () {
      final cartItems = [
        const CartItem(
          menuItem: MenuItem(
            id: 'item-1',
            name: 'فتة موزة',
            description: 'فتة بالأرز والموزة',
            price: 220.0,
            categoryId: 'cat-main',
          ),
          quantity: 1,
        ),
        const CartItem(
          menuItem: MenuItem(
            id: 'item-2',
            name: 'شوربة كوارع',
            description: 'شوربة بلدي',
            price: 80.0,
            categoryId: 'cat-appetizer',
          ),
          quantity: 1,
        ),
      ];

      final result = BillSplittingService.calculateFromCartItems(
        orderId: 'ORD-CART-1',
        cartItems: cartItems,
        guestCount: 2,
      );

      expect(result.shares.length, 2);
      expect(result.shares[0].itemNames.isNotEmpty, isTrue);
      expect(result.shares[1].itemNames.isNotEmpty, isTrue);
    });
  });
}
