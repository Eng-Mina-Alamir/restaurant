import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/enums.dart';
import '../../../orders/domain/entities/order_entity.dart';
import '../../../orders/presentation/controllers/orders_controller.dart';
import '../../domain/entities/financial_report_entity.dart';

enum FinancialPeriod {
  today('اليوم'),
  thisWeek('هذا الأسبوع'),
  thisMonth('هذا الشهر'),
  allTime('كل الفترات');

  final String labelAr;
  const FinancialPeriod(this.labelAr);
}

class FinancialReportsState {
  final FinancialPeriod selectedPeriod;
  final FinancialReportMetrics metrics;

  const FinancialReportsState({
    required this.selectedPeriod,
    required this.metrics,
  });

  FinancialReportsState copyWith({
    FinancialPeriod? selectedPeriod,
    FinancialReportMetrics? metrics,
  }) {
    return FinancialReportsState(
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      metrics: metrics ?? this.metrics,
    );
  }
}

class FinancialReportsController extends StateNotifier<FinancialReportsState> {
  final List<OrderEntity> _orders;

  FinancialReportsController(this._orders)
      : super(
          FinancialReportsState(
            selectedPeriod: FinancialPeriod.allTime,
            metrics: _computeMetrics(_orders, FinancialPeriod.allTime),
          ),
        );

  void setPeriod(FinancialPeriod period) {
    state = state.copyWith(
      selectedPeriod: period,
      metrics: _computeMetrics(_orders, period),
    );
  }

  static FinancialReportMetrics _computeMetrics(
    List<OrderEntity> orders,
    FinancialPeriod period,
  ) {
    final now = DateTime.now();
    final filtered = orders.where((o) {
      if (period == FinancialPeriod.allTime) return true;
      final diff = now.difference(o.createdAt);
      if (period == FinancialPeriod.today) {
        return diff.inDays == 0 && o.createdAt.day == now.day;
      } else if (period == FinancialPeriod.thisWeek) {
        return diff.inDays <= 7;
      } else if (period == FinancialPeriod.thisMonth) {
        return diff.inDays <= 30;
      }
      return true;
    }).toList();

    final completed =
        filtered.where((o) => o.status == OrderStatus.completed).toList();
    final cancelled =
        filtered.where((o) => o.status == OrderStatus.cancelled).toList();

    final grossRevenue = completed.fold<double>(
      0.0,
      (sum, o) => sum + o.totalAmount,
    );

    // COGS estimation (~30% of gross revenue for restaurant ingredients)
    final cogs = grossRevenue * 0.30;

    // Operating costs (~25% of gross revenue for labor, utilities, rent allocation)
    final operatingCosts = grossRevenue * 0.25;

    final grossMargin = grossRevenue - cogs;
    final netProfit = grossMargin - operatingCosts;

    final grossMarginPct =
        grossRevenue > 0 ? (grossMargin / grossRevenue) * 100 : 0.0;
    final netMarginPct =
        grossRevenue > 0 ? (netProfit / grossRevenue) * 100 : 0.0;
    final aov =
        completed.isNotEmpty ? grossRevenue / completed.length : 0.0;

    // Payment methods breakdown
    final payments = <String, double>{
      'نقدي (Cash)': 0.0,
      'بطاقة / مدى (Card)': 0.0,
      'أبل باي (Apple Pay)': 0.0,
      'أخرى / نقاط': 0.0,
    };

    for (final order in completed) {
      final method = order.paymentMethod?.name ?? 'cash';
      if (method.contains('cash')) {
        payments['نقدي (Cash)'] = (payments['نقدي (Cash)'] ?? 0) + order.totalAmount;
      } else if (method.contains('card') || method.contains('mada')) {
        payments['بطاقة / مدى (Card)'] = (payments['بطاقة / مدى (Card)'] ?? 0) + order.totalAmount;
      } else if (method.contains('apple')) {
        payments['أبل باي (Apple Pay)'] = (payments['أبل باي (Apple Pay)'] ?? 0) + order.totalAmount;
      } else {
        payments['أخرى / نقاط'] = (payments['أخرى / نقاط'] ?? 0) + order.totalAmount;
      }
    }

    // Top profitable items aggregation
    final itemSales = <String, _ItemSaleAccumulator>{};
    for (final order in completed) {
      for (final line in order.items) {
        final name = line.menuItem.name;
        final price = line.lineTotal;
        final acc = itemSales.putIfAbsent(name, () => _ItemSaleAccumulator(name));
        acc.units += line.quantity;
        acc.totalRevenue += price;
      }
    }

    final topItems = itemSales.values.map((acc) {
      final cost = acc.totalRevenue * 0.28; // Estimated cost per item
      final profit = acc.totalRevenue - cost;
      final margin = acc.totalRevenue > 0 ? (profit / acc.totalRevenue) * 100 : 0.0;
      return ItemProfitability(
        itemName: acc.name,
        unitsSold: acc.units,
        revenue: acc.totalRevenue,
        estimatedCost: cost,
        profit: profit,
        marginPercent: margin,
      );
    }).toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));

    return FinancialReportMetrics(
      grossRevenue: grossRevenue,
      cogs: cogs,
      operatingCosts: operatingCosts,
      netProfit: netProfit,
      grossMarginPercentage: grossMarginPct,
      netMarginPercentage: netMarginPct,
      averageOrderValue: aov,
      totalOrders: filtered.length,
      completedOrders: completed.length,
      cancelledOrders: cancelled.length,
      paymentBreakdown: payments,
      topProfitableItems: topItems.take(5).toList(),
    );
  }
}

class _ItemSaleAccumulator {
  final String name;
  int units = 0;
  double totalRevenue = 0.0;
  _ItemSaleAccumulator(this.name);
}

final financialReportsControllerProvider =
    StateNotifierProvider<FinancialReportsController, FinancialReportsState>((ref) {
  final orders = ref.watch(ordersControllerProvider);
  return FinancialReportsController(orders);
});
