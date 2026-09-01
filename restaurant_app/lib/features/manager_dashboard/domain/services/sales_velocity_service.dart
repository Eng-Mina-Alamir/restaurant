import '../../../orders/domain/entities/order_entity.dart';
import '../entities/hourly_sales_target_entity.dart';

/// Pure domain service aggregating hourly sales and computing daily target velocity.
abstract final class SalesVelocityService {
  SalesVelocityService._();

  /// Computes hourly distribution across all 24 hours from completed orders.
  static DailyTargetProgress calculateDailyProgress({
    required List<OrderEntity> completedOrders,
    required double dailyTarget,
  }) {
    final Map<int, double> hourlySales = {};
    final Map<int, int> hourlyCounts = {};

    for (int h = 0; h < 24; h++) {
      hourlySales[h] = 0.0;
      hourlyCounts[h] = 0;
    }

    double totalSales = 0.0;

    for (final order in completedOrders) {
      final hour = order.createdAt.hour;
      hourlySales[hour] = (hourlySales[hour] ?? 0.0) + order.totalAmount;
      hourlyCounts[hour] = (hourlyCounts[hour] ?? 0) + 1;
      totalSales += order.totalAmount;
    }

    final targetPerHour = dailyTarget / 14; // assuming 14 operating hours

    final List<HourlySalesPoint> points = [];
    for (int h = 9; h <= 23; h++) {
      // restaurant open hours 9 AM to 11 PM
      points.add(
        HourlySalesPoint(
          hour: h,
          salesAmount: double.parse((hourlySales[h] ?? 0.0).toStringAsFixed(2)),
          ordersCount: hourlyCounts[h] ?? 0,
          targetAmount: double.parse(targetPerHour.toStringAsFixed(2)),
        ),
      );
    }

    return DailyTargetProgress(
      dailyTarget: dailyTarget,
      currentSales: double.parse(totalSales.toStringAsFixed(2)),
      totalOrdersCount: completedOrders.length,
      hourlyPoints: points,
    );
  }
}
