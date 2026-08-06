import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/auth/domain/entities/user_entity.dart';
import 'package:restaurant_app/features/delivery/domain/entities/delivery_assignment.dart';
import 'package:restaurant_app/features/manager_dashboard/domain/entities/sales_metrics.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_entity.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_item.dart';
import 'package:restaurant_app/features/restaurant/domain/entities/restaurant_entity.dart';
import 'package:restaurant_app/features/table_management/domain/entities/restaurant_table.dart';

void main() {
  group('Enums', () {
    test('OrderType.fromName is tolerant', () {
      expect(OrderType.fromName('dineIn'), OrderType.dineIn);
      expect(OrderType.fromName('takeaway'), OrderType.takeaway);
      expect(OrderType.fromName('delivery'), OrderType.delivery);
      expect(OrderType.fromName('unknown'), OrderType.dineIn);
    });

    test('OrderStatus.fromName maps statuses', () {
      expect(OrderStatus.fromName('pending'), OrderStatus.pending);
      expect(OrderStatus.fromName('ready'), OrderStatus.ready);
      expect(OrderStatus.fromName('cancelled'), OrderStatus.cancelled);
    });

    test('OrderStatus labelAr returns Arabic labels', () {
      expect(OrderStatus.pending.labelAr, isNotEmpty);
      expect(OrderStatus.completed.labelAr, 'مكتمل');
    });

    test('UserRole.fromName maps roles', () {
      expect(UserRole.fromName('kitchen'), UserRole.kitchen);
      expect(UserRole.fromName('driver'), UserRole.driver);
      expect(UserRole.driver.homeRoute, '/driver');
    });

    test('TableStatus.fromName maps statuses', () {
      expect(TableStatus.fromName('needsCleaning'), TableStatus.needsCleaning);
      expect(TableStatus.fromName('occupied'), TableStatus.occupied);
    });

    test('PaymentMethod.fromName maps methods', () {
      expect(PaymentMethod.fromName('wallet'), PaymentMethod.wallet);
    });

    test('DeliveryStatus.fromName maps statuses', () {
      expect(DeliveryStatus.fromName('inTransit'), DeliveryStatus.inTransit);
      expect(DeliveryStatus.fromName('delivered'), DeliveryStatus.delivered);
    });
  });

  group('Entity JSON round-trips', () {
    const modifier = MenuModifierOption(
      id: 'm1',
      name: 'جبنة إضافية',
      extraPrice: 5,
    );

    const group = MenuModifierGroup(
      id: 'g1',
      title: 'إضافات',
      isRequired: false,
      maxSelection: 3,
      options: [modifier],
    );

    const menuItem = MenuItem(
      id: 'mi1',
      categoryId: 'c1',
      name: 'برجر',
      description: 'برجر لحم',
      price: 50,
      isVegetarian: false,
      isSpicy: false,
      preparationTime: 15,
      modifierGroups: [group],
      rating: 4.5,
      orderCount: 120,
    );

    test('MenuModifierOption', () {
      final json = modifier.toJson();
      expect(MenuModifierOption.fromJson(json), modifier);
    });

    test('MenuModifierGroup', () {
      final json = group.toJson();
      expect(MenuModifierGroup.fromJson(json), group);
    });

    test('MenuItem', () {
      final json = menuItem.toJson();
      expect(MenuItem.fromJson(json), menuItem);
    });

    test('OrderItem', () {
      final item = OrderItem(
        menuItem: menuItem,
        quantity: 2,
        selectedModifiers: [modifier],
        specialNotes: 'بدون بصل',
        itemTotal: 110,
        addedAt: DateTime(2026, 8, 6, 12, 0),
      );
      final json = item.toJson();
      final restored = OrderItem.fromJson(json);
      expect(restored, item);
      expect(restored.lineTotal, 110);
      expect(restored.unitTotal, 55);
    });

    test('OrderEntity', () {
      final order = OrderEntity(
        id: 'o1',
        restaurantId: 'r1',
        customerId: 'u1',
        tableId: 't1',
        orderType: OrderType.dineIn,
        items: [
          OrderItem(
            menuItem: menuItem,
            quantity: 1,
            itemTotal: 50,
            addedAt: DateTime(2026, 8, 6, 12, 0),
          ),
        ],
        status: OrderStatus.preparing,
        subtotal: 50,
        taxAmount: 7.5,
        discountAmount: 5,
        totalAmount: 52.5,
        paymentMethod: PaymentMethod.card,
        createdAt: DateTime(2026, 8, 6, 12, 0),
        estimatedMinutes: 20,
      );
      final json = order.toJson();
      final restored = OrderEntity.fromJson(json);
      expect(restored, order);
      expect(restored.status, OrderStatus.preparing);
    });

    test('UserEntity', () {
      final user = UserEntity(
        id: 'u1',
        name: 'أحمد',
        email: 'ahmed@example.com',
        phone: '0555555555',
        role: UserRole.waiter,
        restaurantId: 'r1',
        createdAt: DateTime(2026, 8, 6, 12, 0),
      );
      final json = user.toJson();
      final restored = UserEntity.fromJson(json);
      expect(restored, user);
      expect(restored.role, UserRole.waiter);
    });

    test('RestaurantEntity', () {
      const restaurant = RestaurantEntity(
        id: 'r1',
        name: 'مطعمي',
        address: 'الرياض',
        phone: '0111111111',
        latitude: 24.7136,
        longitude: 46.6753,
        totalTables: 20,
        categories: ['برجر', 'بيتزا'],
      );
      final json = restaurant.toJson();
      expect(RestaurantEntity.fromJson(json), restaurant);
    });

    test('RestaurantTable', () {
      const table = RestaurantTable(
        id: 't1',
        tableNumber: 5,
        capacity: 6,
        status: TableStatus.occupied,
        currentOrderId: 'o1',
      );
      final json = table.toJson();
      expect(RestaurantTable.fromJson(json), table);
    });

    test('DeliveryAssignment', () {
      final assignment = DeliveryAssignment(
        id: 'd1',
        orderId: 'o1',
        driverId: 'dr1',
        pickupTime: DateTime(2026, 8, 6, 12, 0),
        deliveryLocation: 'حي النخيل',
        latitude: 24.7,
        longitude: 46.6,
        deliveryStatus: DeliveryStatus.inTransit,
        deliveryFee: 15,
      );
      final json = assignment.toJson();
      expect(DeliveryAssignment.fromJson(json), assignment);
    });

    test('SalesMetrics', () {
      const metrics = SalesMetrics(
        totalSales: 1500,
        totalOrders: 30,
        averageOrderValue: 50,
        itemsSold: {'برجر': 20},
        peakHour: 20,
        prepTimeAverage: 18,
      );
      final json = metrics.toJson();
      expect(SalesMetrics.fromJson(json), metrics);
    });
  });
}
