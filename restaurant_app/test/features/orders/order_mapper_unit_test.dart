import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/domain/order_mapper.dart';

void main() {
  group('OrderMapper Unit Tests', () {
    const meal = MenuItem(
      id: 'm1',
      categoryId: 'cat1',
      name: 'فراخ مشوية',
      description: 'نصف دجاجة مشوية',
      price: 60.0,
    );

    const modifier = MenuModifierOption(
      id: 'mod1',
      name: 'أرز إضافي',
      extraPrice: 15.0,
    );

    final now = DateTime(2026, 8, 19, 12, 0);

    test('toOrderItem maps CartItem fields with calculated linePrice', () {
      const cartItem = CartItem(
        menuItem: meal,
        quantity: 2,
        selectedModifiers: [modifier],
        specialNotes: 'حار جداً',
      );

      final orderItem = OrderMapper.toOrderItem(cartItem, timestamp: now);

      expect(orderItem.menuItem.id, 'm1');
      expect(orderItem.quantity, 2);
      // (60 + 15) * 2 = 150
      expect(orderItem.itemTotal, 150.0);
      expect(orderItem.specialNotes, 'حار جداً');
      expect(orderItem.addedAt, now);
    });

    test('buildForCustomer constructs a takeaway OrderEntity with 15% tax', () {
      const cartItems = [
        CartItem(menuItem: meal, quantity: 1), // 60
      ];

      final order = OrderMapper.buildForCustomer(
        orderId: 'ORD-100',
        restaurantId: 'rest-1',
        cartItems: cartItems,
        createdAt: now,
        paymentMethod: PaymentMethod.wallet,
      );

      expect(order.id, 'ORD-100');
      expect(order.orderType, OrderType.takeaway);
      expect(order.status, OrderStatus.pending);
      expect(order.paymentMethod, PaymentMethod.wallet);
      expect(order.subtotal, 60.0);
      expect(order.taxAmount, closeTo(9.0, 0.001)); // 60 * 0.15 = 9
      expect(order.totalAmount, closeTo(69.0, 0.001));
      expect(order.estimatedMinutes, 25);
    });

    test('buildForTable constructs a dineIn OrderEntity with tableId', () {
      const cartItems = [
        CartItem(menuItem: meal, quantity: 2), // 120
      ];

      final order = OrderMapper.buildForTable(
        orderId: 'ORD-200',
        restaurantId: 'rest-1',
        tableId: 'tbl-7',
        cartItems: cartItems,
        createdAt: now,
        paymentMethod: PaymentMethod.cash,
      );

      expect(order.id, 'ORD-200');
      expect(order.orderType, OrderType.dineIn);
      expect(order.tableId, 'tbl-7');
      expect(order.status, OrderStatus.pending);
      expect(order.subtotal, 120.0);
      expect(order.taxAmount, closeTo(18.0, 0.001)); // 120 * 0.15 = 18
      expect(order.totalAmount, closeTo(138.0, 0.001));
      expect(order.estimatedMinutes, 20);
    });
  });
}
