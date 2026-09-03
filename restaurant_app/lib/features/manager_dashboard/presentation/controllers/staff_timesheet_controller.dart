import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/app_config.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../core/utils/logger.dart';
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
  StaffTimesheetController({SupabaseClient? supabase})
      : _supabase = supabase,
        super(
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
        ) {
    if (_supabase != null) {
      _loadFromSupabase();
    }
  }

  final SupabaseClient? _supabase;

  Future<void> _loadFromSupabase() async {
    final client = _supabase;
    if (client == null) return;
    try {
      final rows = await client
          .from('staff_timesheets')
          .select()
          .order('clock_in', ascending: false);

      if (rows.isNotEmpty) {
        final List<StaffAttendanceRecord> records = [];
        for (final r in (rows as List)) {
          final m = Map<String, dynamic>.from(r as Map);
          final roleStr = m['role']?.toString() ?? 'waiter';
          final role = UserRole.values.firstWhere(
            (val) => val.name == roleStr,
            orElse: () => UserRole.waiter,
          );

          records.add(
            StaffAttendanceRecord(
              id: m['id']?.toString() ?? '',
              staffId: m['user_id']?.toString() ?? '',
              staffName: m['staff_name']?.toString() ?? '',
              role: role,
              clockInAt: DateTime.tryParse(m['clock_in']?.toString() ?? '') ?? DateTime.now(),
              clockOutAt: m['clock_out'] != null ? DateTime.tryParse(m['clock_out'].toString()) : null,
              hourlyWage: 40.0,
            ),
          );
        }
        state = StaffTimesheetState(records: records);
      }
    } catch (e) {
      AppLogger.warning('StaffTimesheetController loadFromSupabase error: $e');
    }
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

    final client = _supabase;
    if (client != null) {
      Future.microtask(() async {
        try {
          await client.from('staff_timesheets').insert({
            'id': newRecord.id,
            'restaurant_id': '1e08b47c-15be-4604-a913-431af7fbd54f',
            'user_id': staffId.contains('-') && staffId.length >= 32
                ? staffId
                : '8f6fd7bb-b10a-4ca9-80e4-f27e5c0cec38',
            'staff_name': staffName,
            'role': role.name,
            'clock_in': newRecord.clockInAt.toIso8601String(),
            'break_minutes': 0,
            'status': 'onDuty',
            'notes': 'تسجيل حضور تلقائي',
            'created_at': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          AppLogger.warning('StaffTimesheet clockIn sync error: $e');
        }
      });
    }

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

    final client = _supabase;
    if (client != null) {
      Future.microtask(() async {
        try {
          await client.from('staff_timesheets').update({
            'clock_out': DateTime.now().toIso8601String(),
            'status': 'completed',
          }).eq('id', recordId);
        } catch (e) {
          AppLogger.warning('StaffTimesheet clockOut sync error: $e');
        }
      });
    }
  }
}

/// Riverpod provider for [StaffTimesheetController].
final staffTimesheetControllerProvider =
    StateNotifierProvider<StaffTimesheetController, StaffTimesheetState>((ref) {
      final supabase = AppConfig.useSupabase ? ref.watch(supabaseClientProvider) : null;
      return StaffTimesheetController(supabase: supabase);
    });
