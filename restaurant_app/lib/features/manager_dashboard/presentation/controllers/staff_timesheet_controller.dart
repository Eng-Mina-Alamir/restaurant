import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/enums.dart';
import '../../domain/entities/staff_timesheet_entity.dart';
import '../../domain/services/staff_timesheet_service.dart';

/// State of staff timesheet and active shifts.
class StaffTimesheetState {
  const StaffTimesheetState({
    this.records = const [],
  });

  final List<StaffAttendanceRecord> records;

  List<StaffAttendanceRecord> get activeStaffOnDuty =>
      records.where((r) => r.isActiveOnDuty).toList();

  LaborCostMetrics calculateMetrics(double totalSalesRevenue) {
    return StaffTimesheetService.calculateLaborMetrics(
      records: records,
      totalSalesRevenue: totalSalesRevenue,
    );
  }

  StaffTimesheetState copyWith({
    List<StaffAttendanceRecord>? records,
  }) {
    return StaffTimesheetState(
      records: records ?? this.records,
    );
  }
}

/// Controller managing staff clock-in / clock-out and labor cost tracking.
class StaffTimesheetController extends StateNotifier<StaffTimesheetState> {
  StaffTimesheetController()
      : super(
          StaffTimesheetState(
            records: [
              StaffAttendanceRecord(
                id: 'ATT-1',
                staffId: 'user-cashier-1',
                staffName: 'حسام علي',
                role: UserRole.cashier,
                clockInAt: DateTime.now().subtract(const Duration(hours: 4, minutes: 30)),
                hourlyWage: 40.0,
              ),
              StaffAttendanceRecord(
                id: 'ATT-2',
                staffId: 'user-waiter-1',
                staffName: 'أحمد شريف',
                role: UserRole.waiter,
                clockInAt: DateTime.now().subtract(const Duration(hours: 5)),
                hourlyWage: 35.0,
              ),
              StaffAttendanceRecord(
                id: 'ATT-3',
                staffId: 'user-kitchen-1',
                staffName: 'الشيف محمود',
                role: UserRole.kitchen,
                clockInAt: DateTime.now().subtract(const Duration(hours: 6)),
                hourlyWage: 55.0,
              ),
            ],
          ),
        );

  /// Records Clock-In for a staff member.
  StaffAttendanceRecord clockIn({
    required String staffId,
    required String staffName,
    required UserRole role,
    double hourlyWage = 35.0,
  }) {
    final newRecord = StaffAttendanceRecord(
      id: 'ATT-${DateTime.now().millisecondsSinceEpoch}',
      staffId: staffId,
      staffName: staffName,
      role: role,
      clockInAt: DateTime.now(),
      hourlyWage: hourlyWage,
    );

    state = state.copyWith(records: [newRecord, ...state.records]);
    return newRecord;
  }

  /// Records Clock-Out for a staff member.
  void clockOut(String recordId) {
    final updated = state.records.map((r) {
      if (r.id == recordId && r.isActiveOnDuty) {
        return r.copyWith(clockOutAt: DateTime.now());
      }
      return r;
    }).toList();

    state = state.copyWith(records: updated);
  }
}

/// Riverpod provider for [StaffTimesheetController].
final staffTimesheetControllerProvider =
    StateNotifierProvider<StaffTimesheetController, StaffTimesheetState>((ref) {
      return StaffTimesheetController();
    });
