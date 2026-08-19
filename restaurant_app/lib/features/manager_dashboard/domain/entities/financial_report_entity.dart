class FinancialReportMetrics {
  final double grossRevenue;
  final double cogs; // Cost of Goods Sold
  final double operatingCosts;
  final double netProfit;
  final double grossMarginPercentage;
  final double netMarginPercentage;
  final double averageOrderValue;
  final int totalOrders;
  final int completedOrders;
  final int cancelledOrders;
  final Map<String, double> paymentBreakdown;
  final List<ItemProfitability> topProfitableItems;

  const FinancialReportMetrics({
    required this.grossRevenue,
    required this.cogs,
    required this.operatingCosts,
    required this.netProfit,
    required this.grossMarginPercentage,
    required this.netMarginPercentage,
    required this.averageOrderValue,
    required this.totalOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.paymentBreakdown,
    required this.topProfitableItems,
  });
}

class ItemProfitability {
  final String itemName;
  final int unitsSold;
  final double revenue;
  final double estimatedCost;
  final double profit;
  final double marginPercent;

  const ItemProfitability({
    required this.itemName,
    required this.unitsSold,
    required this.revenue,
    required this.estimatedCost,
    required this.profit,
    required this.marginPercent,
  });
}
