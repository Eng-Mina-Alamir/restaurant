/// Driver Wallet & Shift Cash-in-Hand Entity
class DriverWalletEntity {
  const DriverWalletEntity({
    this.driverId = 'driver-1',
    this.driverName = 'كابتن أحمد علي',
    this.openingFloat = 500.0,
    this.collectedCod = 0.0,
    this.collectedTips = 0.0,
    this.earnedCommission = 0.0,
    this.completedDeliveriesCount = 0,
    this.isSettled = false,
    this.lastSettledAt,
  });

  final String driverId;
  final String driverName;

  /// عهدة الفكة المستلمة من الكاشير في بداية الشيفت (مثلاً 500 جنيه)
  final double openingFloat;

  /// إجمالي المبالغ النقدية المحصلة من العملاء (Cash on Delivery)
  final double collectedCod;

  /// إجمالي البقشيش / الإكراميات المحصلة
  final double collectedTips;

  /// إجمالي العمولات المستحقة للسائق عن رحلات التوصيل
  final double earnedCommission;

  /// عدد الرحلات المكتملة بنجاح
  final int completedDeliveriesCount;

  /// هل تم تصفية وتسليم العهدة للكاشير في ختام الشيفت
  final bool isSettled;

  /// توقيت آخر تصفية
  final DateTime? lastSettledAt;

  /// إجمالي الكاش الموجود في جيب السائق حالياً
  /// (العهدة الأساسية + الكاش المحصل من العملاء + البقشيش)
  double get totalCashInHand => isSettled ? 0.0 : (openingFloat + collectedCod + collectedTips);

  /// المبلغ المستحق تسليمه للكاشير في نهاية الشيفت
  /// (العهدة الأساسية + أموال المطعم المحصلة من الوجبات)
  double get remittanceDueToCashier => isSettled ? 0.0 : (openingFloat + collectedCod);

  /// صافي أرباح السائق الخاصة (العمولات + البقشيش)
  double get totalDriverEarnings => earnedCommission + collectedTips;

  DriverWalletEntity copyWith({
    String? driverId,
    String? driverName,
    double? openingFloat,
    double? collectedCod,
    double? collectedTips,
    double? earnedCommission,
    int? completedDeliveriesCount,
    bool? isSettled,
    DateTime? lastSettledAt,
  }) {
    return DriverWalletEntity(
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      openingFloat: openingFloat ?? this.openingFloat,
      collectedCod: collectedCod ?? this.collectedCod,
      collectedTips: collectedTips ?? this.collectedTips,
      earnedCommission: earnedCommission ?? this.earnedCommission,
      completedDeliveriesCount:
          completedDeliveriesCount ?? this.completedDeliveriesCount,
      isSettled: isSettled ?? this.isSettled,
      lastSettledAt: lastSettledAt ?? this.lastSettledAt,
    );
  }
}
