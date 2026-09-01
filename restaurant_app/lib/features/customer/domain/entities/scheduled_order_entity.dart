import 'package:flutter/foundation.dart';

/// Configuration and slot information for an advance scheduled order.
@immutable
class ScheduledOrderSlot {
  const ScheduledOrderSlot({
    required this.targetDateTime,
    this.preparationLeadMinutes = 30,
    this.specialScheduleNote,
  });

  final DateTime targetDateTime;
  final int preparationLeadMinutes;
  final String? specialScheduleNote;

  /// The timestamp when the kitchen should begin actively preparing this order.
  DateTime get kitchenStartPreparationTime =>
      targetDateTime.subtract(Duration(minutes: preparationLeadMinutes));

  /// Checks whether this slot is scheduled in the future with sufficient lead time.
  bool get isValidSchedule {
    final now = DateTime.now();
    return targetDateTime.isAfter(now.add(Duration(minutes: preparationLeadMinutes)));
  }

  ScheduledOrderSlot copyWith({
    DateTime? targetDateTime,
    int? preparationLeadMinutes,
    String? specialScheduleNote,
  }) {
    return ScheduledOrderSlot(
      targetDateTime: targetDateTime ?? this.targetDateTime,
      preparationLeadMinutes: preparationLeadMinutes ?? this.preparationLeadMinutes,
      specialScheduleNote: specialScheduleNote ?? this.specialScheduleNote,
    );
  }
}
