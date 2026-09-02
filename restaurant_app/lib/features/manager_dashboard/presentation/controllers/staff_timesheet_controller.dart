import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/domain/enums.dart';
import '../../data/repositories/supabase_manager_operations_repository.dart';
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
  StaffTimesheetController([this._repository]) : super(const StaffTimesheetState()) {
    loadTimesheets();
  }

  final SupabaseManagerOperationsRepository? _repository;

  Future<void> loadTimesheets() async {
    if (_repository == null) return;
    final result = await _repository.getTimesheets();
    result.when(
      onLeft: (_) {},
      onRight: (entries) {
        if (mounted) {
          state = state.copyWith(records: entries);
        }
      },
    );
  }

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
    _repository?.saveTimesheet(newRecord);
    return newRecord;
  }

  /// Records Clock-Out for a staff member.
  void clockOut(String recordId) {
    final updated = state.records.map((r) {
      if (r.id == recordId && r.isActiveOnDuty) {
        final mod = r.copyWith(clockOutAt: DateTime.now());
        _repository?.saveTimesheet(mod);
        return mod;
      }
      return r;
    }).toList();

    state = state.copyWith(records: updated);
  }
}

/// Riverpod provider for [StaffTimesheetController].
final staffTimesheetControllerProvider =
    StateNotifierProvider<StaffTimesheetController, StaffTimesheetState>((ref) {
      final repo = ref.watch(supabaseManagerOperationsRepositoryProvider);
      return StaffTimesheetController(repo);
    });
