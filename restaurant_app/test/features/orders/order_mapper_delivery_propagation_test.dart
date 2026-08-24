import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_entity.dart';
import 'package:restaurant_app/features/orders/domain/order_mapper.dart';

void main() {
  group('OrderMapper Delivery Propagation', () {
    const meal = MenuItem(
      id: 'm1',
      categoryId: 'cat1',
      name: 'بيتزا مارغريتا',
      description: 'عجينة طازجة وجبنة موزاريلا',
      price: 80.0,
    );

    final now = DateTime(2026, 8, 22, 13, 30);

    const cartItems = [
      CartItem(menuItem: meal, quantity: 2), // 160
    ];

    test('buildForCustomer defaults to takeaway when orderType is null', () {
      final order = OrderMapper.buildForCustomer(
        orderId: 'ORD-100',
        restaurantId: 'rest-1',
        cartItems: cartItems,
        createdAt: now,
      );

      expect(order.orderType, OrderType.takeaway);
      expect(order.deliveryAddress, isNull);
      expect(order.deliveryNotes, isNull);
      expect(order.estimatedMinutes, 25);
    });

    test('buildForCustomer propagates dineIn order type', () {
      final order = OrderMapper.buildForCustomer(
        orderId: 'ORD-101',
        restaurantId: 'rest-1',
        cartItems: cartItems,
        createdAt: now,
        orderType: OrderType.dineIn,
      );

      expect(order.orderType, OrderType.dineIn);
    });

    test(
      'buildForCustomer propagates delivery order type with address/notes',
      () {
        final order = OrderMapper.buildForCustomer(
          orderId: 'ORD-102',
          restaurantId: 'rest-1',
          cartItems: cartItems,
          createdAt: now,
          orderType: OrderType.delivery,
          deliveryAddress: 'حي الزمالك، شارع 26 يوليو، القاهرة',
          deliveryNotes: 'الدور الثالث، جرس الشقة 5',
        );

        expect(order.orderType, OrderType.delivery);
        expect(order.deliveryAddress, 'حي الزمالك، شارع 26 يوليو، القاهرة');
        expect(order.deliveryNotes, 'الدور الثالث، جرس الشقة 5');
        expect(order.status, OrderStatus.pending);
        expect(order.totalAmount, closeTo(184.0, 0.001)); // 160 * 1.15
      },
    );

    test('delivery address and notes survive toJson/fromJson round-trip', () {
      final order = OrderMapper.buildForCustomer(
        orderId: 'ORD-103',
        restaurantId: 'rest-1',
        cartItems: cartItems,
        createdAt: now,
        paymentMethod: PaymentMethod.cash,
        orderType: OrderType.delivery,
        deliveryAddress: 'مدينة نصر، شارع عباس العقاد',
        deliveryNotes: 'اتصل عند الوصول',
      );

      final json = order.toJson();
      // Serialization must actually carry the fields.
      expect(json['orderType'], 'delivery');
      expect(json['deliveryAddress'], 'مدينة نصر، شارع عباس العقاد');
      expect(json['deliveryNotes'], 'اتصل عند الوصول');

      final deserialized = OrderEntity.fromJson(json);
      expect(deserialized.id, order.id);
      expect(deserialized.orderType, OrderType.delivery);
      expect(deserialized.deliveryAddress, 'مدينة نصر، شارع عباس العقاد');
      expect(deserialized.deliveryNotes, 'اتصل عند الوصول');
      expect(deserialized.status, OrderStatus.pending);
      expect(deserialized.paymentMethod, PaymentMethod.cash);
      expect(deserialized.createdAt, now);
    });

    test('buildForDelivery produces a delivery-type order with address', () {
      final order = OrderMapper.buildForDelivery(
        orderId: 'ORD-104',
        restaurantId: 'rest-1',
        deliveryAddress: 'المعادي، شارع 9',
        cartItems: cartItems,
        createdAt: now,
        paymentMethod: PaymentMethod.card,
        deliveryNotes: 'البوابة الخلفية',
      );

      expect(order.orderType, OrderType.delivery);
      expect(order.status, OrderStatus.pending);
      expect(order.deliveryAddress, 'المعادي، شارع 9');
      expect(order.deliveryNotes, 'البوابة الخلفية');
      expect(order.paymentMethod, PaymentMethod.card);
      // Delivery ETA ≈ 40 minutes (preparation + transit).
      expect(order.estimatedMinutes, 40);
      expect(order.subtotal, 160.0);
      expect(order.taxAmount, closeTo(24.0, 0.001)); // 160 * 0.15
      expect(order.totalAmount, closeTo(184.0, 0.001));
    });
  });
}
