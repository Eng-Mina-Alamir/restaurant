import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/manager_dashboard/presentation/controllers/metrics_controller.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_entity.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_item.dart';

void main() {
  group('computeMetrics Unit Tests', () {
    const item1 = MenuItem(
      id: 'i1',
      categoryId: 'grills',
      name: 'كباب',
      description: '',
      price: 50.0,
    );

    const item2 = MenuItem(
      id: 'i2',
      categoryId: 'drinks',
      name: 'عصير برتقال',
      description: '',
      price: 20.0,
    );

    test('returns empty SalesMetrics on empty orders list', () {
      final metrics = computeMetrics([]);
      expect(metrics.totalSales, 0.0);
      expect(metrics.totalOrders, 0);
      expect(metrics.averageOrderValue, 0.0);
      expect(metrics.itemsSold, isEmpty);
    });

    test('calculates totalSales from completed orders only and aggregates popularity', () {
      final now = DateTime.now();

      final completedOrder = OrderEntity(
        id: 'ORD-1',
        restaurantId: 'r1',
        orderType: OrderType.dineIn,
        status: OrderStatus.completed,
        items: [
          OrderItem(menuItem: item1, quantity: 2, itemTotal: 100.0, addedAt: now),
          OrderItem(menuItem: item2, quantity: 1, itemTotal: 20.0, addedAt: now),
        ],
        subtotal: 120.0,
        taxAmount: 18.0,
        totalAmount: 138.0,
        paymentMethod: PaymentMethod.card,
        createdAt: now,
      );

      final pendingOrder = OrderEntity(
        id: 'ORD-2',
        restaurantId: 'r1',
        orderType: OrderType.delivery,
        status: OrderStatus.pending,
        items: [
          OrderItem(menuItem: item1, quantity: 1, itemTotal: 50.0, addedAt: now),
        ],
        subtotal: 50.0,
        taxAmount: 7.5,
        totalAmount: 57.5,
        paymentMethod: PaymentMethod.cash,
        createdAt: now,
      );

      final metrics = computeMetrics([completedOrder, pendingOrder]);

      expect(metrics.totalOrders, 2);
      expect(metrics.totalSales, 138.0); // Only completed order
      expect(metrics.averageOrderValue, 138.0 / 2);
      expect(metrics.itemsSold['كباب'], 3); // 2 from first + 1 from second
      expect(metrics.itemsSold['عصير برتقال'], 1);
      expect(metrics.categoryRevenue['grills'], 150.0);
      expect(metrics.categoryRevenue['drinks'], 20.0);
    });
  });
}
