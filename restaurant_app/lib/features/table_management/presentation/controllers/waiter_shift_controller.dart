import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/waiter_shift_stats_entity.dart';

/// StateNotifier for tracking the active waiter's live shift performance and tips.
class WaiterShiftController extends StateNotifier<WaiterShiftStatsEntity> {
  WaiterShiftController(String waiterId, String waiterName)
    : super(
        WaiterShiftStatsEntity(
          waiterId: waiterId,
          waiterName: waiterName,
          shiftDate: DateTime.now(),
          tablesServedCount: 4,
          guestsServedCount: 14,
          totalSalesVolume: 1840.0,
          cashTipsCollected: 160.0,
          creditTipsCollected: 85.0,
          activeOccupiedTables: 2,
          averageTableDurationMinutes: 32,
        ),
      );

  /// Records a completed table checkout with sales volume and tip.
  void recordTableCheckout({
    required double tableBill,
    required double tipAmount,
    required bool isCashTip,
    required int guestCount,
  }) {
    state = state.copyWith(
      tablesServedCount: state.tablesServedCount + 1,
      guestsServedCount: state.guestsServedCount + guestCount,
      totalSalesVolume: state.totalSalesVolume + tableBill,
      cashTipsCollected:
          isCashTip
              ? state.cashTipsCollected + tipAmount
              : state.cashTipsCollected,
      creditTipsCollected:
          !isCashTip
              ? state.creditTipsCollected + tipAmount
              : state.creditTipsCollected,
      activeOccupiedTables:
          state.activeOccupiedTables > 0 ? state.activeOccupiedTables - 1 : 0,
    );
  }

  /// Increments active occupied tables count when seating a new table.
  void recordTableSeated(int guests) {
    state = state.copyWith(
      activeOccupiedTables: state.activeOccupiedTables + 1,
    );
  }

  /// Settles shift and prints/records the end-of-shift remittance.
  void settleShift() {
    state = state.copyWith(
      isShiftSettled: true,
      settledAt: DateTime.now(),
      activeOccupiedTables: 0,
    );
  }

  /// Resets shift for testing or next day.
  void resetShift() {
    state = WaiterShiftStatsEntity(
      waiterId: state.waiterId,
      waiterName: state.waiterName,
      shiftDate: DateTime.now(),
      tablesServedCount: 0,
      guestsServedCount: 0,
      totalSalesVolume: 0.0,
      cashTipsCollected: 0.0,
      creditTipsCollected: 0.0,
      activeOccupiedTables: 0,
    );
  }
}

/// Provider for [WaiterShiftController].
final waiterShiftControllerProvider =
    StateNotifierProvider<WaiterShiftController, WaiterShiftStatsEntity>((ref) {
      final authUser = ref.watch(authControllerProvider).user;
      final waiterId = authUser?.id ?? 'waiter-demo';
      final waiterName = authUser?.name ?? 'كابتن أحمد';

      return WaiterShiftController(waiterId, waiterName);
    });
