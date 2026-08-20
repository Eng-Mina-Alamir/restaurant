import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/manager_dashboard/presentation/controllers/financial_reports_controller.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_entity.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_item.dart';

void main() {
  const burger = MenuItem(
    id: 'm1',
    categoryId: 'burgers',
    name: 'برجر لحم',
    description: 'وصف',
    price: 50.0,
  );

  final now = DateTime.now();

  final order1 = OrderEntity(
    id: 'ORD-1',
    restaurantId: 'rest-1',
    orderType: OrderType.dineIn,
    status: OrderStatus.completed,
    paymentMethod: PaymentMethod.card,
    items: [
      OrderItem(
        menuItem: burger,
        quantity: 2,
        itemTotal: 100.0,
        addedAt: now,
      ),
    ],
    subtotal: 100.0,
    taxAmount: 15.0,
    totalAmount: 115.0,
    createdAt: now,
  );

  final order2 = OrderEntity(
    id: 'ORD-2',
    restaurantId: 'rest-1',
    orderType: OrderType.takeaway,
    status: OrderStatus.cancelled,
    paymentMethod: PaymentMethod.cash,
    items: [
      OrderItem(
        menuItem: burger,
        quantity: 1,
        itemTotal: 50.0,
        addedAt: now,
      ),
    ],
    subtotal: 50.0,
    taxAmount: 7.5,
    totalAmount: 57.5,
    createdAt: now,
  );

  group('FinancialReportsController Unit Tests', () {
    test('computes correct financial metrics for orders list', () {
      final controller = FinancialReportsController([order1, order2]);

      final state = controller.state;
      expect(state.selectedPeriod, FinancialPeriod.allTime);

      final metrics = state.metrics;
      expect(metrics.totalOrders, 2);
      expect(metrics.completedOrders, 1);
      expect(metrics.cancelledOrders, 1);
      expect(metrics.grossRevenue, 115.0);
      expect(metrics.cogs, closeTo(115.0 * 0.30, 0.001));
      expect(metrics.operatingCosts, closeTo(115.0 * 0.25, 0.001));
      expect(metrics.netProfit, closeTo(115.0 * 0.45, 0.001));
      expect(metrics.averageOrderValue, 115.0);
      expect(metrics.topProfitableItems.isNotEmpty, isTrue);
      expect(metrics.topProfitableItems.first.itemName, 'برجر لحم');
    });

    test('setPeriod changes period and filters appropriately', () {
      final oldOrder = OrderEntity(
        id: 'ORD-OLD',
        restaurantId: 'rest-1',
        orderType: OrderType.dineIn,
        status: OrderStatus.completed,
        paymentMethod: PaymentMethod.card,
        items: [],
        subtotal: 200.0,
        taxAmount: 30.0,
        totalAmount: 230.0,
        createdAt: now.subtract(const Duration(days: 45)),
      );

      final controller = FinancialReportsController([order1, oldOrder]);

      controller.setPeriod(FinancialPeriod.allTime);
      expect(controller.state.metrics.totalOrders, 2);

      controller.setPeriod(FinancialPeriod.today);
      expect(controller.state.selectedPeriod, FinancialPeriod.today);
      expect(controller.state.metrics.totalOrders, 1);
    });
  });
}
