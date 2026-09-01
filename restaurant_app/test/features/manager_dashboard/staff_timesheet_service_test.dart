import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/manager_dashboard/domain/entities/staff_timesheet_entity.dart';
import 'package:restaurant_app/features/manager_dashboard/domain/services/staff_timesheet_service.dart';

void main() {
  group('StaffTimesheetService Tests', () {
    test('Calculates regular wage and overtime wage accurately', () {
      final clockIn = DateTime(2026, 9, 1, 9, 0);
      final clockOut = DateTime(2026, 9, 1, 19, 0); // 10 hours = 8 regular + 2 overtime

      final record = StaffAttendanceRecord(
        id: 'ATT-1',
        staffId: 'staff-1',
        staffName: 'أحمد',
        role: UserRole.waiter,
        clockInAt: clockIn,
        clockOutAt: clockOut,
        hourlyWage: 40.0,
      );

      expect(record.durationHours, 10.0);
      expect(record.regularHours, 8.0);
      expect(record.overtimeHours, 2.0);

      // 8 * 40 + 2 * (40 * 1.5) = 320 + 120 = 440 EGP
      expect(record.calculatedShiftWage, 440.0);
      expect(record.isActiveOnDuty, isFalse);
    });

    test('Computes labor cost percentage against revenue correctly', () {
      final records = [
        StaffAttendanceRecord(
          id: 'ATT-1',
          staffId: 'staff-1',
          staffName: 'أحمد',
          role: UserRole.waiter,
          clockInAt: DateTime(2026, 9, 1, 9, 0),
          clockOutAt: DateTime(2026, 9, 1, 17, 0), // 8h * 40 = 320
          hourlyWage: 40.0,
        ),
        StaffAttendanceRecord(
          id: 'ATT-2',
          staffId: 'staff-2',
          staffName: 'محمود',
          role: UserRole.kitchen,
          clockInAt: DateTime(2026, 9, 1, 9, 0),
          clockOutAt: DateTime(2026, 9, 1, 17, 0), // 8h * 60 = 480
          hourlyWage: 60.0,
        ),
      ];

      // Total payroll = 320 + 480 = 800 EGP
      // Revenue = 3200 EGP
      // Labor Cost % = (800 / 3200) * 100 = 25.0%
      final metrics = StaffTimesheetService.calculateLaborMetrics(
        records: records,
        totalSalesRevenue: 3200.0,
      );

      expect(metrics.totalWagesCost, 800.0);
      expect(metrics.laborCostPercentage, 25.0);
      expect(metrics.totalHoursWorked, 16.0);
      expect(metrics.activeStaffCount, 0);
      expect(metrics.healthStatusAr.contains('ممتاز'), isTrue);
    });
  });
}
