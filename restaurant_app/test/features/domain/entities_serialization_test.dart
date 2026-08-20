import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/coupons/domain/entities/coupon_entity.dart';
import 'package:restaurant_app/features/delivery/domain/entities/delivery_assignment.dart';
import 'package:restaurant_app/features/inventory/domain/entities/inventory_item_entity.dart';
import 'package:restaurant_app/features/manager_dashboard/domain/entities/alert_entity.dart';
import 'package:restaurant_app/features/manager_dashboard/domain/entities/sales_metrics.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_entity.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_item.dart';
import 'package:restaurant_app/features/ratings/domain/entities/rating_entity.dart';
import 'package:restaurant_app/features/reservations/domain/entities/reservation_entity.dart';
import 'package:restaurant_app/features/table_management/domain/entities/restaurant_table.dart';

void main() {
  group('Entities Serialization & Round-Trip', () {
    test('MenuItem serialization and copyWith', () {
      const item = MenuItem(
        id: 'menu-1',
        categoryId: 'cat-1',
        name: 'شاورما',
        description: 'شاورما عربي',
        price: 25.0,
        imageUrl: 'https://example.com/img.jpg',
        isAvailable: true,
        isVegetarian: false,
        isSpicy: true,
      );

      final json = item.toJson();
      final fromJson = MenuItem.fromJson(json);

      expect(fromJson.id, item.id);
      expect(fromJson.name, item.name);
      expect(fromJson.price, item.price);
      expect(fromJson.isSpicy, true);

      final updated = item.copyWith(price: 30.0, isAvailable: false);
      expect(updated.price, 30.0);
      expect(updated.isAvailable, false);
      expect(updated.id, item.id);
    });

    test('OrderEntity and OrderItem serialization and round-trip', () {
      final now = DateTime.now();
      final orderItem = OrderItem(
        menuItem: const MenuItem(
          id: 'item-1',
          categoryId: 'cat-1',
          name: 'بيتزا',
          description: 'بيتزا مارجريتا',
          price: 45.0,
        ),
        quantity: 2,
        itemTotal: 90.0,
        addedAt: now,
      );

      final order = OrderEntity(
        id: 'ORD-777',
        restaurantId: 'rest-1',
        tableId: 'tbl-12',
        orderType: OrderType.dineIn,
        status: OrderStatus.preparing,
        paymentMethod: PaymentMethod.card,
        items: [orderItem],
        subtotal: 90.0,
        taxAmount: 13.5,
        totalAmount: 103.5,
        createdAt: now,
        estimatedMinutes: 20,
      );

      final json = order.toJson();
      final fromJson = OrderEntity.fromJson(json);

      expect(fromJson.id, 'ORD-777');
      expect(fromJson.tableId, 'tbl-12');
      expect(fromJson.status, OrderStatus.preparing);
      expect(fromJson.orderType, OrderType.dineIn);
      expect(fromJson.paymentMethod, PaymentMethod.card);
      expect(fromJson.items.length, 1);
      expect(fromJson.items.first.itemTotal, 90.0);
    });

    test('RestaurantTable serialization', () {
      final now = DateTime.now();
      final table = RestaurantTable(
        id: 'tbl-1',
        tableNumber: 5,
        capacity: 4,
        status: TableStatus.occupied,
        assignedWaiterId: 'waiter-9',
        currentOrderId: 'ORD-123',
        lastUpdated: now,
      );

      final json = table.toJson();
      final fromJson = RestaurantTable.fromJson(json);

      expect(fromJson.id, 'tbl-1');
      expect(fromJson.tableNumber, 5);
      expect(fromJson.capacity, 4);
      expect(fromJson.status, TableStatus.occupied);
      expect(fromJson.assignedWaiterId, 'waiter-9');
      expect(fromJson.currentOrderId, 'ORD-123');
    });

    test('DeliveryAssignment serialization', () {
      final now = DateTime.now();
      final assignment = DeliveryAssignment(
        id: 'DEL-101',
        orderId: 'ORD-101',
        driverId: 'driver-1',
        deliveryLocation: 'شارع الملك فهد',
        customerPhone: '0501234567',
        deliveryStatus: DeliveryStatus.inTransit,
        pickupTime: now,
      );

      final json = assignment.toJson();
      final fromJson = DeliveryAssignment.fromJson(json);

      expect(fromJson.id, 'DEL-101');
      expect(fromJson.driverId, 'driver-1');
      expect(fromJson.deliveryStatus, DeliveryStatus.inTransit);
    });

    test('SalesMetrics serialization', () {
      const metrics = SalesMetrics(
        totalSales: 5000.0,
        totalOrders: 100,
        averageOrderValue: 50.0,
        itemsSold: {'برجر': 40, 'بيتزا': 60},
        categoryRevenue: {'وجبات': 3000.0, 'مشروبات': 2000.0},
        paymentMethodRevenue: {'نقدي': 2000.0, 'بطاقة': 3000.0},
      );

      final json = metrics.toJson();
      final fromJson = SalesMetrics.fromJson(json);

      expect(fromJson.totalSales, 5000.0);
      expect(fromJson.totalOrders, 100);
      expect(fromJson.averageOrderValue, 50.0);
      expect(fromJson.itemsSold['برجر'], 40);
    });

    test('InventoryItemEntity, CouponEntity, RatingEntity, ReservationEntity, AlertEntity models', () {
      final now = DateTime.now();

      const inv = InventoryItemEntity(
        id: 'inv-1',
        name: 'سكر',
        category: 'خامات',
        currentStock: 50.0,
        unit: 'كجم',
        minThreshold: 10.0,
        costPerUnit: 4.5,
      );
      expect(inv.id, 'inv-1');
      expect(inv.status, StockStatus.sufficient);
      expect(inv.copyWith(currentStock: 5.0).status, StockStatus.low);

      final coupon = CouponEntity(
        id: 'c-1',
        code: 'SAVE20',
        title: 'خصم 20%',
        discountType: CouponDiscountType.percentage,
        discountValue: 20.0,
        isActive: true,
        validUntil: now.add(const Duration(days: 7)),
      );
      expect(coupon.code, 'SAVE20');
      expect(coupon.validate(100.0), isNull);
      expect(coupon.calculateDiscount(100.0), 20.0);

      final rating = RatingEntity(
        id: 'rate-1',
        targetId: 'item-1',
        targetType: RatingTargetType.menuItem,
        userId: 'u-1',
        userName: 'خالد',
        score: 4.5,
        comment: 'ممتاز',
        createdAt: now,
      );
      expect(rating.score, 4.5);

      final res = ReservationEntity(
        id: 'res-1',
        customerName: 'محمد',
        customerPhone: '0555555555',
        tableId: 'tbl-1',
        tableNumber: 1,
        guestCount: 3,
        reservationTime: now,
        status: ReservationStatus.confirmed,
        createdAt: now,
      );
      expect(res.customerName, 'محمد');
      expect(res.status, ReservationStatus.confirmed);

      final alert = AlertEntity(
        id: 'alt-1',
        title: 'تنبيه',
        message: 'رسالة',
        severity: AlertSeverity.warning,
        category: AlertCategory.inventory,
        createdAt: now,
      );
      expect(alert.isRead, isFalse);
      expect(alert.copyWith(isRead: true).isRead, isTrue);
    });
  });
}
