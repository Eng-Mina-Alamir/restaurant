import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_entity.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_item.dart';

void main() {
  group('OrderEntity and OrderItem Serialization Tests', () {
    const item = MenuItem(
      id: 'item-1',
      categoryId: 'cat-1',
      name: 'شاورما دجاج',
      description: 'شاورما مع ثومية',
      price: 35.0,
    );

    final now = DateTime(2026, 8, 19, 15, 0);

    final orderItem = OrderItem(
      menuItem: item,
      quantity: 2,
      itemTotal: 70.0,
      specialNotes: 'زيادة ثومية',
      addedAt: now,
    );

    test('OrderItem serialization round-trip', () {
      final json = {
        'menuItem': item.toJson(),
        'quantity': 2,
        'itemTotal': 70.0,
        'specialNotes': 'زيادة ثومية',
        'addedAt': now.toIso8601String(),
      };

      final deserialized = OrderItem.fromJson(json);
      expect(deserialized.menuItem.id, 'item-1');
      expect(deserialized.itemTotal, 70.0);
      expect(deserialized.quantity, 2);
      expect(deserialized.specialNotes, 'زيادة ثومية');
    });

    test('OrderEntity serialization round-trip with all properties', () {
      final order = OrderEntity(
        id: 'ORD-5001',
        restaurantId: 'rest-cairo',
        customerId: 'usr-1',
        tableId: 'tbl-3',
        waiterId: 'w-1',
        orderType: OrderType.dineIn,
        items: [orderItem],
        status: OrderStatus.preparing,
        subtotal: 70.0,
        taxAmount: 10.5,
        discountAmount: 5.0,
        totalAmount: 75.5,
        paymentMethod: PaymentMethod.card,
        deliveryAddress: 'شارع الهرم',
        deliveryNotes: 'الدور الثالث',
        createdAt: now,
        estimatedMinutes: 25,
      );

      final json = {
        'id': 'ORD-5001',
        'restaurantId': 'rest-cairo',
        'customerId': 'usr-1',
        'tableId': 'tbl-3',
        'waiterId': 'w-1',
        'orderType': 'dineIn',
        'items': [orderItem.toJson()],
        'status': 'preparing',
        'subtotal': 70.0,
        'taxAmount': 10.5,
        'discountAmount': 5.0,
        'totalAmount': 75.5,
        'paymentMethod': 'card',
        'deliveryAddress': 'شارع الهرم',
        'deliveryNotes': 'الدور الثالث',
        'createdAt': now.toIso8601String(),
        'estimatedMinutes': 25,
      };

      final deserialized = OrderEntity.fromJson(json);
      expect(deserialized.id, order.id);
      expect(deserialized.orderType, OrderType.dineIn);
      expect(deserialized.status, OrderStatus.preparing);
      expect(deserialized.paymentMethod, PaymentMethod.card);
      expect(deserialized.items, hasLength(1));
    });

    test(
      'OrderStatus isTerminal helper returns true only for completed and cancelled',
      () {
        expect(OrderStatus.pending.isTerminal, isFalse);
        expect(OrderStatus.confirmed.isTerminal, isFalse);
        expect(OrderStatus.preparing.isTerminal, isFalse);
        expect(OrderStatus.ready.isTerminal, isFalse);
        expect(OrderStatus.served.isTerminal, isFalse);
        expect(OrderStatus.completed.isTerminal, isTrue);
        expect(OrderStatus.cancelled.isTerminal, isTrue);
      },
    );
  });
}
