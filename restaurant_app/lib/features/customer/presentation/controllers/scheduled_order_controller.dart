import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/scheduled_order_entity.dart';

/// Controller for managing order pre-scheduling and target time slots.
class ScheduledOrderController extends StateNotifier<ScheduledOrderSlot?> {
  ScheduledOrderController() : super(null);

  /// Sets or updates the scheduled delivery/pickup time.
  void setSchedule({
    required DateTime targetDateTime,
    int preparationLeadMinutes = 30,
    String? note,
  }) {
    state = ScheduledOrderSlot(
      targetDateTime: targetDateTime,
      preparationLeadMinutes: preparationLeadMinutes,
      specialScheduleNote: note,
    );
  }

  /// Clears scheduled slot and reverts to ASAP / Instant order.
  void clearSchedule() {
    state = null;
  }
}

final scheduledOrderControllerProvider =
    StateNotifierProvider<ScheduledOrderController, ScheduledOrderSlot?>((ref) {
  return ScheduledOrderController();
});
