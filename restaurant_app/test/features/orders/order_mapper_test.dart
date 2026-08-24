import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/domain/order_mapper.dart';

void main() {
  const burger = MenuItem(
    id: 'm1',
    categoryId: 'burgers',
    name: 'برجر كلاسيك',
    description: 'شريحة لحم مع الصوص',
    price: 30.0,
  );

  const cheeseModifier = MenuModifierOption(
    id: 'mod1',
    name: 'إضافة جبنة',
    extraPrice: 5.0,
  );

  group('OrderMapper', () {
    test('toOrderItem maps cart item correctly', () {
      final now = DateTime(2026, 8, 19, 12, 0);
      const cartItem = CartItem(
        menuItem: burger,
        quantity: 2,
        selectedModifiers: [cheeseModifier],
        specialNotes: 'بدون بصل',
      );

      final orderItem = OrderMapper.toOrderItem(cartItem, timestamp: now);

      expect(orderItem.menuItem.id, 'm1');
      expect(orderItem.quantity, 2);
      expect(orderItem.selectedModifiers.length, 1);
      expect(orderItem.specialNotes, 'بدون بصل');
      expect(orderItem.itemTotal, 70.0); // (30 + 5) * 2
      expect(orderItem.addedAt, now);
    });

    test('buildForCustomer creates takeaway order with accurate totals', () {
      final now = DateTime(2026, 8, 19, 14, 30);
      const items = [
        CartItem(menuItem: burger, quantity: 2), // 60
      ];

      final order = OrderMapper.buildForCustomer(
        orderId: 'ORD-0001',
        restaurantId: 'rest-123',
        cartItems: items,
        createdAt: now,
        paymentMethod: PaymentMethod.card,
      );

      expect(order.id, 'ORD-0001');
      expect(order.restaurantId, 'rest-123');
      expect(order.orderType, OrderType.takeaway);
      expect(order.status, OrderStatus.pending);
      expect(order.paymentMethod, PaymentMethod.card);
      expect(order.items.length, 1);
      expect(order.subtotal, 60.0);
      expect(order.taxAmount, closeTo(9.0, 0.001)); // 15% of 60
      expect(order.totalAmount, closeTo(69.0, 0.001));
      expect(order.estimatedMinutes, 25);
      expect(order.createdAt, now);
    });

    test('buildForTable creates dineIn order linked to tableId', () {
      final now = DateTime(2026, 8, 19, 15, 0);
      const items = [CartItem(menuItem: burger, quantity: 1)];

      final order = OrderMapper.buildForTable(
        orderId: 'ORD-0002',
        restaurantId: 'rest-123',
        tableId: 'tbl-05',
        cartItems: items,
        createdAt: now,
        paymentMethod: PaymentMethod.cash,
      );

      expect(order.id, 'ORD-0002');
      expect(order.restaurantId, 'rest-123');
      expect(order.tableId, 'tbl-05');
      expect(order.orderType, OrderType.dineIn);
      expect(order.status, OrderStatus.pending);
      expect(order.paymentMethod, PaymentMethod.cash);
      expect(order.items.length, 1);
      expect(order.subtotal, 30.0);
      expect(order.taxAmount, closeTo(4.5, 0.001));
      expect(order.totalAmount, closeTo(34.5, 0.001));
      expect(order.estimatedMinutes, 20);
    });
  });
}
