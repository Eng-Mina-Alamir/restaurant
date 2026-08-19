import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_entity.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_item.dart';
import 'package:restaurant_app/features/manager_dashboard/presentation/controllers/financial_reports_controller.dart';

void main() {
  group('Financial Reports & P&L Tests', () {
    late List<OrderEntity> testOrders;

    setUp(() {
      final burgerItem = OrderItem(
        menuItem: const MenuItem(
          id: 'm1',
          categoryId: 'برجر',
          name: 'برجر لحم كلاسيك',
          description: 'وصف',
          price: 40.0,
        ),
        quantity: 2,
        addedAt: DateTime.now(),
      );

      final pizzaItem = OrderItem(
        menuItem: const MenuItem(
          id: 'm2',
          categoryId: 'بيتزا',
          name: 'بيتزا مارجريتا',
          description: 'وصف',
          price: 60.0,
        ),
        quantity: 1,
        addedAt: DateTime.now(),
      );

      testOrders = [
        OrderEntity(
          id: 'ord-1',
          restaurantId: 'rest-1',
          orderType: OrderType.dineIn,
          status: OrderStatus.completed,
          items: [burgerItem],
          subtotal: 80.0,
          taxAmount: 12.0,
          totalAmount: 92.0,
          paymentMethod: PaymentMethod.card,
          createdAt: DateTime.now(),
        ),
        OrderEntity(
          id: 'ord-2',
          restaurantId: 'rest-1',
          orderType: OrderType.delivery,
          status: OrderStatus.completed,
          items: [pizzaItem],
          subtotal: 60.0,
          taxAmount: 9.0,
          totalAmount: 69.0,
          paymentMethod: PaymentMethod.cash,
          createdAt: DateTime.now(),
        ),
        OrderEntity(
          id: 'ord-3',
          restaurantId: 'rest-1',
          orderType: OrderType.takeaway,
          status: OrderStatus.cancelled,
          items: [burgerItem],
          subtotal: 80.0,
          taxAmount: 12.0,
          totalAmount: 92.0,
          createdAt: DateTime.now(),
        ),
      ];
    });

    test('computes gross revenue from completed orders only', () {
      final controller = FinancialReportsController(testOrders);
      final metrics = controller.state.metrics;

      // 92.0 (ord-1) + 69.0 (ord-2) = 161.0 SAR
      expect(metrics.grossRevenue, 161.0);
      expect(metrics.completedOrders, 2);
      expect(metrics.cancelledOrders, 1);
      expect(metrics.totalOrders, 3);
    });

    test('computes COGS, gross margin and net profit accurately', () {
      final controller = FinancialReportsController(testOrders);
      final metrics = controller.state.metrics;

      // COGS is 30% of 161 = 48.3
      expect(metrics.cogs, 48.3);

      // Operating costs is 25% of 161 = 40.25
      expect(metrics.operatingCosts, 40.25);

      // Net profit = 161 - 48.3 - 40.25 = 72.45
      expect(metrics.netProfit, 72.45);
      expect(metrics.grossMarginPercentage, 70.0);
      expect(metrics.netMarginPercentage, 45.0);
    });

    test('calculates average order value (AOV) and payment distribution', () {
      final controller = FinancialReportsController(testOrders);
      final metrics = controller.state.metrics;

      // AOV = 161.0 / 2 = 80.5 SAR
      expect(metrics.averageOrderValue, 80.5);

      expect(metrics.paymentBreakdown['بطاقة / مدى (Card)'], 92.0);
      expect(metrics.paymentBreakdown['نقدي (Cash)'], 69.0);
    });

    test('ranks top profitable items by revenue', () {
      final controller = FinancialReportsController(testOrders);
      final metrics = controller.state.metrics;

      expect(metrics.topProfitableItems.isNotEmpty, isTrue);
      // Burger has higher revenue (80.0) than Pizza (60.0)
      expect(metrics.topProfitableItems.first.itemName, 'برجر لحم كلاسيك');
      expect(metrics.topProfitableItems.first.profit > 0, isTrue);
    });
  });
}
