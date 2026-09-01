import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/manager_dashboard/domain/services/sales_velocity_service.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_entity.dart';

void main() {
  group('SalesVelocityService Tests', () {
    test('Calculates hourly sales distribution and target progress', () {
      final now = DateTime.now();
      final orders = [
        OrderEntity(
          id: '1',
          restaurantId: 'rest-1',
          orderType: OrderType.dineIn,
          status: OrderStatus.completed,
          totalAmount: 1200.0,
          paymentMethod: PaymentMethod.cash,
          createdAt: DateTime(now.year, now.month, now.day, 14, 30), // 2 PM
        ),
        OrderEntity(
          id: '2',
          restaurantId: 'rest-1',
          orderType: OrderType.dineIn,
          status: OrderStatus.completed,
          totalAmount: 800.0,
          paymentMethod: PaymentMethod.card,
          createdAt: DateTime(now.year, now.month, now.day, 14, 45), // 2 PM
        ),
        OrderEntity(
          id: '3',
          restaurantId: 'rest-1',
          orderType: OrderType.dineIn,
          status: OrderStatus.completed,
          totalAmount: 500.0,
          paymentMethod: PaymentMethod.cash,
          createdAt: DateTime(now.year, now.month, now.day, 20, 15), // 8 PM
        ),
      ];

      final progress = SalesVelocityService.calculateDailyProgress(
        completedOrders: orders,
        dailyTarget: 10000.0,
      );

      expect(progress.currentSales, 2500.0);
      expect(progress.dailyTarget, 10000.0);
      expect(progress.percentageAchieved, 25.0);
      expect(progress.totalOrdersCount, 3);
      expect(progress.averageTicketSize, double.parse((2500.0 / 3).toStringAsFixed(2)));

      // Peak hour should be 14 (2 PM) with 2000.0 EGP
      final point2PM = progress.hourlyPoints.firstWhere((p) => p.hour == 14);
      expect(point2PM.salesAmount, 2000.0);
      expect(point2PM.ordersCount, 2);
      expect(point2PM.isRushPeakHour, isTrue);
      expect(progress.peakRushHour?.hour, 14);
    });
  });
}
