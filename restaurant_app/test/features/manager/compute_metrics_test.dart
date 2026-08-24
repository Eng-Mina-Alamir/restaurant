import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/manager_dashboard/presentation/controllers/metrics_controller.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_entity.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_item.dart';

void main() {
  const burger = MenuItem(
    id: 'm1',
    categoryId: 'fast_food',
    name: 'برجر',
    description: 'لذيذ',
    price: 30.0,
  );

  const drink = MenuItem(
    id: 'm2',
    categoryId: 'drinks',
    name: 'عصير برتقال',
    description: 'طازج',
    price: 15.0,
  );

  final now = DateTime.now();

  group('computeMetrics pure function tests', () {
    test('returns zeroed metrics for empty order list', () {
      final metrics = computeMetrics(const []);
      expect(metrics.totalSales, 0.0);
      expect(metrics.totalOrders, 0);
      expect(metrics.averageOrderValue, 0.0);
      expect(metrics.itemsSold, isEmpty);
      expect(metrics.categoryRevenue, isEmpty);
      expect(metrics.paymentMethodRevenue, isEmpty);
    });

    test(
      'computes total sales only from completed orders while aggregating items from all orders',
      () {
        final orderCompleted = OrderEntity(
          id: 'ORD-1',
          restaurantId: 'rest-1',
          orderType: OrderType.dineIn,
          status: OrderStatus.completed,
          paymentMethod: PaymentMethod.card,
          items: [
            OrderItem(
              menuItem: burger,
              quantity: 2,
              itemTotal: 60.0,
              addedAt: now,
            ),
            OrderItem(
              menuItem: drink,
              quantity: 1,
              itemTotal: 15.0,
              addedAt: now,
            ),
          ],
          subtotal: 75.0,
          taxAmount: 11.25,
          totalAmount: 86.25,
          createdAt: now,
        );

        final orderPending = OrderEntity(
          id: 'ORD-2',
          restaurantId: 'rest-1',
          orderType: OrderType.takeaway,
          status: OrderStatus.pending,
          paymentMethod: PaymentMethod.cash,
          items: [
            OrderItem(
              menuItem: burger,
              quantity: 1,
              itemTotal: 30.0,
              addedAt: now,
            ),
          ],
          subtotal: 30.0,
          taxAmount: 4.5,
          totalAmount: 34.5,
          createdAt: now,
        );

        final metrics = computeMetrics([orderCompleted, orderPending]);

        expect(metrics.totalOrders, 2);
        expect(metrics.totalSales, 86.25);
        expect(metrics.averageOrderValue, closeTo(86.25 / 2, 0.001));

        // Items sold across all orders
        expect(metrics.itemsSold['برجر'], 3); // 2 + 1
        expect(metrics.itemsSold['عصير برتقال'], 1);

        // Category revenue
        expect(metrics.categoryRevenue['fast_food'], 90.0); // 60 + 30
        expect(metrics.categoryRevenue['drinks'], 15.0);

        // Payment method revenue
        expect(metrics.paymentMethodRevenue[PaymentMethod.card.labelAr], 86.25);
        expect(metrics.paymentMethodRevenue[PaymentMethod.cash.labelAr], 34.5);
      },
    );
  });
}
