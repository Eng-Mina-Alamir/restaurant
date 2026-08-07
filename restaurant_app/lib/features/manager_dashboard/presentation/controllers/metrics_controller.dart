import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/constants.dart';
import '../../../../core/domain/enums.dart';
import '../../../orders/domain/entities/order_entity.dart';
import '../../../orders/presentation/controllers/orders_controller.dart';
import '../../domain/entities/sales_metrics.dart';

/// Computes live [SalesMetrics] from the session's orders.
///
/// Watches [ordersControllerProvider] so the manager dashboard updates as
/// orders are placed and fulfilled. Pure arithmetic (no remote dependency).
class MetricsController extends AsyncNotifier<SalesMetrics> {
  @override
  Future<SalesMetrics> build() async {
    final orders = ref.watch(ordersControllerProvider);
    return computeMetrics(orders);
  }
}

/// Pure function: derives [SalesMetrics] from [orders].
///
/// Kept top-level so it is trivially unit-testable.
SalesMetrics computeMetrics(List<OrderEntity> orders) {
  if (orders.isEmpty) {
    return const SalesMetrics();
  }

  final completed = orders
      .where((o) => o.status == OrderStatus.completed)
      .toList();
  final totalSales = completed.fold<double>(0, (sum, o) => sum + o.totalAmount);

  // Item popularity across all orders.
  final itemsSold = <String, int>{};
  final categoryRevenue = <String, double>{};
  final paymentMethodRevenue = <String, double>{};
  for (final order in orders) {
    for (final item in order.items) {
      itemsSold[item.menuItem.name] =
          (itemsSold[item.menuItem.name] ?? 0) + item.quantity;
      categoryRevenue[item.menuItem.categoryId] =
          (categoryRevenue[item.menuItem.categoryId] ?? 0) + item.itemTotal;
    }
    final paymentLabel =
        order.paymentMethod?.labelAr ?? AppConstants.paymentUnknown;
    paymentMethodRevenue[paymentLabel] =
        (paymentMethodRevenue[paymentLabel] ?? 0) + order.totalAmount;
  }

  return SalesMetrics(
    totalSales: totalSales,
    totalOrders: orders.length,
    averageOrderValue: orders.isEmpty ? 0 : totalSales / orders.length,
    itemsSold: itemsSold,
    categoryRevenue: categoryRevenue,
    paymentMethodRevenue: paymentMethodRevenue,
  );
}

final metricsControllerProvider =
    AsyncNotifierProvider<MetricsController, SalesMetrics>(
      MetricsController.new,
    );
