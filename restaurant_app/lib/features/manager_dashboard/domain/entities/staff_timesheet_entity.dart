import '../../../../core/domain/enums.dart';

/// A recorded staff attendance and timesheet entry.
class StaffAttendanceRecord {
  const StaffAttendanceRecord({
    required this.id,
    required this.staffId,
    required this.staffName,
    required this.role,
    required this.clockInAt,
    this.clockOutAt,
    this.hourlyWage = 35.0, // EGP / hour
    this.notes,
  });

  final String id;
  final String staffId;
  final String staffName;
  final UserRole role;
  final DateTime clockInAt;
  final DateTime? clockOutAt;
  final double hourlyWage;
  final String? notes;

  bool get isActiveOnDuty => clockOutAt == null;

  /// Duration worked in hours (e.g. 8.5 hours).
  double get durationHours {
    final end = clockOutAt ?? DateTime.now();
    final diffMinutes = end.difference(clockInAt).inMinutes;
    return diffMinutes / 60.0;
  }

  /// Regular hours (up to standard 8 hours / shift).
  double get regularHours => durationHours.clamp(0.0, 8.0);

  /// Overtime hours (> 8 hours).
  double get overtimeHours => (durationHours - 8.0).clamp(0.0, 24.0);

  /// Calculated monetary cost for this shift (Regular + 1.5x Overtime).
  double get calculatedShiftWage {
    final regularPay = regularHours * hourlyWage;
    final overtimePay = overtimeHours * (hourlyWage * 1.5);
    return double.parse((regularPay + overtimePay).toStringAsFixed(2));
  }

  StaffAttendanceRecord copyWith({
    String? id,
    String? staffId,
    String? staffName,
    UserRole? role,
    DateTime? clockInAt,
    DateTime? clockOutAt,
    double? hourlyWage,
    String? notes,
  }) {
    return StaffAttendanceRecord(
      id: id ?? this.id,
      staffId: staffId ?? this.staffId,
      staffName: staffName ?? this.staffName,
      role: role ?? this.role,
      clockInAt: clockInAt ?? this.clockInAt,
      clockOutAt: clockOutAt ?? this.clockOutAt,
      hourlyWage: hourlyWage ?? this.hourlyWage,
      notes: notes ?? this.notes,
    );
  }
}

/// Aggregated labor cost metrics compared against restaurant revenue.
class LaborCostMetrics {
  const LaborCostMetrics({
    required this.totalWagesCost,
    required this.totalSalesRevenue,
    required this.activeStaffCount,
    required this.totalHoursWorked,
  });

  final double totalWagesCost;
  final double totalSalesRevenue;
  final int activeStaffCount;
  final double totalHoursWorked;

  /// Labor Cost % = (Total Wages / Total Sales) * 100
  double get laborCostPercentage {
    if (totalSalesRevenue <= 0) return 0.0;
    final pct = (totalWagesCost / totalSalesRevenue) * 100;
    return double.parse(pct.toStringAsFixed(1));
  }

  /// Evaluates if labor cost is optimal (25%-30%), low (<25%), or high (>30%).
  String get healthStatusAr {
    if (totalSalesRevenue <= 0) return 'بانتظار تسجيل المبيعات';
    if (laborCostPercentage <= 25.0) return 'ممتاز (تكلفة عمالة منخفضة ومثالية)';
    if (laborCostPercentage <= 30.0) return 'جيد (ضمن المعدل المعياري الطبيعي)';
    return 'مرتفع ⚠️ (يجب مراجعة ساعات العمل أو زيادة المبيعات)';
  }
}
