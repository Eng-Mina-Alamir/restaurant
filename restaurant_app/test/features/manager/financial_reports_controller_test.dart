import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/manager_dashboard/presentation/controllers/financial_reports_controller.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_entity.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_item.dart';

void main() {
  group('FinancialReportsController and Period Filtering Tests', () {
    const meal = MenuItem(
      id: 'i1',
      categoryId: 'c1',
      name: 'طاجن بامية باللحم',
      description: '',
      price: 80.0,
    );

    final completedOrder = OrderEntity(
      id: 'ORD-10',
      restaurantId: 'r1',
      orderType: OrderType.dineIn,
      status: OrderStatus.completed,
      items: [
        OrderItem(
          menuItem: meal,
          quantity: 2,
          itemTotal: 160.0,
          addedAt: DateTime.now(),
        ),
      ],
      subtotal: 160.0,
      taxAmount: 24.0,
      totalAmount: 184.0,
      paymentMethod: PaymentMethod.card,
      createdAt: DateTime.now(),
    );

    test(
      'calculates gross revenue, COGS, operating costs, and margins correctly',
      () {
        final controller = FinancialReportsController([completedOrder]);

        final metrics = controller.state.metrics;
        expect(metrics.grossRevenue, 184.0);
        expect(metrics.completedOrders, 1);
        // cogs = 184 * 0.30 = 55.2
        expect(metrics.cogs, closeTo(55.2, 0.001));
        // operatingCosts = 184 * 0.25 = 46.0
        expect(metrics.operatingCosts, closeTo(46.0, 0.001));
        // netProfit = (184 - 55.2) - 46.0 = 82.8
        expect(metrics.netProfit, closeTo(82.8, 0.001));
        expect(metrics.topProfitableItems, hasLength(1));
        expect(metrics.topProfitableItems.first.itemName, 'طاجن بامية باللحم');
      },
    );

    test('switching period filters orders and updates metrics', () {
      final oldOrder = OrderEntity(
        id: 'ORD-OLD',
        restaurantId: 'r1',
        orderType: OrderType.dineIn,
        status: OrderStatus.completed,
        items: [
          OrderItem(
            menuItem: meal,
            quantity: 1,
            itemTotal: 80.0,
            addedAt: DateTime.now().subtract(const Duration(days: 45)),
          ),
        ],
        subtotal: 80.0,
        taxAmount: 12.0,
        totalAmount: 92.0,
        paymentMethod: PaymentMethod.cash,
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
      );

      final controller = FinancialReportsController([completedOrder, oldOrder]);

      // All time includes both
      expect(controller.state.metrics.completedOrders, 2);

      // Today includes only today's order
      controller.setPeriod(FinancialPeriod.today);
      expect(controller.state.selectedPeriod, FinancialPeriod.today);
      expect(controller.state.metrics.completedOrders, 1);
    });
  });
}
