import '../entities/staff_timesheet_entity.dart';

/// Pure domain service calculating staff hours, shift wages, and restaurant labor cost KPIs.
abstract final class StaffTimesheetService {
  StaffTimesheetService._();

  /// Calculates total monetary wages across all attendance records.
  static double calculateTotalWagesCost(List<StaffAttendanceRecord> records) {
    return records.fold<double>(0.0, (acc, r) => acc + r.calculatedShiftWage);
  }

  /// Calculates total hours worked across all staff records.
  static double calculateTotalHoursWorked(List<StaffAttendanceRecord> records) {
    return records.fold<double>(0.0, (acc, r) => acc + r.durationHours);
  }

  /// Generates the [LaborCostMetrics] comparing total staff payroll against daily sales.
  static LaborCostMetrics calculateLaborMetrics({
    required List<StaffAttendanceRecord> records,
    required double totalSalesRevenue,
  }) {
    final totalCost = calculateTotalWagesCost(records);
    final totalHours = calculateTotalHoursWorked(records);
    final activeCount = records.where((r) => r.isActiveOnDuty).length;

    return LaborCostMetrics(
      totalWagesCost: totalCost,
      totalSalesRevenue: totalSalesRevenue,
      activeStaffCount: activeCount,
      totalHoursWorked: double.parse(totalHours.toStringAsFixed(1)),
    );
  }
}
