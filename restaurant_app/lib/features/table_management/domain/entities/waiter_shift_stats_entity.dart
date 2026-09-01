/// Realtime and shift-end performance and tips tracker for a floor waiter / captain.
class WaiterShiftStatsEntity {
  const WaiterShiftStatsEntity({
    required this.waiterId,
    required this.waiterName,
    required this.shiftDate,
    this.tablesServedCount = 0,
    this.guestsServedCount = 0,
    this.totalSalesVolume = 0.0,
    this.cashTipsCollected = 0.0,
    this.creditTipsCollected = 0.0,
    this.activeOccupiedTables = 0,
    this.averageTableDurationMinutes = 35,
    this.isShiftSettled = false,
    this.settledAt,
  });

  final String waiterId;
  final String waiterName;
  final DateTime shiftDate;
  final int tablesServedCount;
  final int guestsServedCount;
  final double totalSalesVolume;
  final double cashTipsCollected;
  final double creditTipsCollected;
  final int activeOccupiedTables;
  final int averageTableDurationMinutes;
  final bool isShiftSettled;
  final DateTime? settledAt;

  double get totalTips => cashTipsCollected + creditTipsCollected;

  double get tipPercentageOnSales =>
      totalSalesVolume > 0 ? (totalTips / totalSalesVolume) * 100 : 0.0;

  WaiterShiftStatsEntity copyWith({
    String? waiterId,
    String? waiterName,
    DateTime? shiftDate,
    int? tablesServedCount,
    int? guestsServedCount,
    double? totalSalesVolume,
    double? cashTipsCollected,
    double? creditTipsCollected,
    int? activeOccupiedTables,
    int? averageTableDurationMinutes,
    bool? isShiftSettled,
    DateTime? settledAt,
  }) {
    return WaiterShiftStatsEntity(
      waiterId: waiterId ?? this.waiterId,
      waiterName: waiterName ?? this.waiterName,
      shiftDate: shiftDate ?? this.shiftDate,
      tablesServedCount: tablesServedCount ?? this.tablesServedCount,
      guestsServedCount: guestsServedCount ?? this.guestsServedCount,
      totalSalesVolume: totalSalesVolume ?? this.totalSalesVolume,
      cashTipsCollected: cashTipsCollected ?? this.cashTipsCollected,
      creditTipsCollected: creditTipsCollected ?? this.creditTipsCollected,
      activeOccupiedTables: activeOccupiedTables ?? this.activeOccupiedTables,
      averageTableDurationMinutes:
          averageTableDurationMinutes ?? this.averageTableDurationMinutes,
      isShiftSettled: isShiftSettled ?? this.isShiftSettled,
      settledAt: settledAt ?? this.settledAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'waiterId': waiterId,
    'waiterName': waiterName,
    'shiftDate': shiftDate.toIso8601String(),
    'tablesServedCount': tablesServedCount,
    'guestsServedCount': guestsServedCount,
    'totalSalesVolume': totalSalesVolume,
    'cashTipsCollected': cashTipsCollected,
    'creditTipsCollected': creditTipsCollected,
    'activeOccupiedTables': activeOccupiedTables,
    'averageTableDurationMinutes': averageTableDurationMinutes,
    'isShiftSettled': isShiftSettled,
    'settledAt': settledAt?.toIso8601String(),
  };

  factory WaiterShiftStatsEntity.fromJson(Map<String, dynamic> json) {
    return WaiterShiftStatsEntity(
      waiterId: json['waiterId'] as String,
      waiterName: json['waiterName'] as String,
      shiftDate: DateTime.parse(json['shiftDate'] as String),
      tablesServedCount: json['tablesServedCount'] as int? ?? 0,
      guestsServedCount: json['guestsServedCount'] as int? ?? 0,
      totalSalesVolume: (json['totalSalesVolume'] as num?)?.toDouble() ?? 0.0,
      cashTipsCollected:
          (json['cashTipsCollected'] as num?)?.toDouble() ?? 0.0,
      creditTipsCollected:
          (json['creditTipsCollected'] as num?)?.toDouble() ?? 0.0,
      activeOccupiedTables: json['activeOccupiedTables'] as int? ?? 0,
      averageTableDurationMinutes:
          json['averageTableDurationMinutes'] as int? ?? 35,
      isShiftSettled: json['isShiftSettled'] as bool? ?? false,
      settledAt:
          json['settledAt'] != null
              ? DateTime.parse(json['settledAt'] as String)
              : null,
    );
  }
}
