/// Sales and volume stats for a single hour of the operational day.
class HourlySalesPoint {
  const HourlySalesPoint({
    required this.hour, // 0 to 23 (e.g. 14 for 2:00 PM)
    required this.salesAmount,
    required this.ordersCount,
    required this.targetAmount,
  });

  final int hour;
  final double salesAmount;
  final int ordersCount;
  final double targetAmount;

  String get hourFormattedAr {
    final period = hour >= 12 ? 'م' : 'ص';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:00 $period';
  }

  bool get isRushPeakHour => ordersCount >= 8 || salesAmount >= 1500.0;
}

/// Overall daily target metrics and performance progress.
class DailyTargetProgress {
  const DailyTargetProgress({
    required this.dailyTarget,
    required this.currentSales,
    required this.totalOrdersCount,
    required this.hourlyPoints,
  });

  final double dailyTarget;
  final double currentSales;
  final int totalOrdersCount;
  final List<HourlySalesPoint> hourlyPoints;

  /// Percentage of target achieved (e.g. 78.5%).
  double get percentageAchieved {
    if (dailyTarget <= 0) return 0.0;
    final pct = (currentSales / dailyTarget) * 100;
    return double.parse(pct.toStringAsFixed(1));
  }

  /// Average spend per customer ticket.
  double get averageTicketSize {
    if (totalOrdersCount <= 0) return 0.0;
    final avg = currentSales / totalOrdersCount;
    return double.parse(avg.toStringAsFixed(2));
  }

  /// Finds peak rush hour of the day.
  HourlySalesPoint? get peakRushHour {
    if (hourlyPoints.isEmpty) return null;
    return hourlyPoints.reduce((curr, next) => curr.salesAmount > next.salesAmount ? curr : next);
  }
}
