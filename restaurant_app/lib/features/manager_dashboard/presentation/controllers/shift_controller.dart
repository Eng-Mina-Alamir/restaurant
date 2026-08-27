import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/shift_entity.dart';

class ShiftState {
  final ShiftEntity? activeShift;
  final List<ShiftEntity> shiftHistory;

  const ShiftState({
    this.activeShift,
    this.shiftHistory = const [],
  });

  ShiftState copyWith({
    ShiftEntity? activeShift,
    List<ShiftEntity>? shiftHistory,
    bool clearActiveShift = false,
  }) {
    return ShiftState(
      activeShift: clearActiveShift ? null : (activeShift ?? this.activeShift),
      shiftHistory: shiftHistory ?? this.shiftHistory,
    );
  }
}

class ShiftController extends StateNotifier<ShiftState> {
  ShiftController()
    : super(
        ShiftState(
          activeShift: ShiftEntity(
            id: 'SHIFT-101',
            cashierId: 'usr-1',
            cashierName: 'أحمد محمد',
            openedAt: DateTime.now().subtract(const Duration(hours: 4)),
            openingCashFloat: 500.0,
            status: ShiftStatus.open,
          ),
          shiftHistory: [],
        ),
      );

  /// Opens a new cash drawer shift.
  void openShift({
    required String cashierId,
    required String cashierName,
    required double openingFloat,
  }) {
    final shift = ShiftEntity(
      id: 'SHIFT-${DateTime.now().millisecondsSinceEpoch}',
      cashierId: cashierId,
      cashierName: cashierName,
      openedAt: DateTime.now(),
      openingCashFloat: openingFloat,
      status: ShiftStatus.open,
    );
    state = state.copyWith(activeShift: shift);
  }

  /// Closes the active shift, calculates discrepancy, and stores to history.
  ShiftEntity? closeShift({
    required double actualCashCount,
    required double cashSales,
    required double cardSales,
    required double walletSales,
    required int orderCount,
    String? notes,
  }) {
    final current = state.activeShift;
    if (current == null) return null;

    final closed = current.copyWith(
      closedAt: DateTime.now(),
      status: ShiftStatus.closed,
      cashSales: cashSales,
      cardSales: cardSales,
      walletSales: walletSales,
      totalOrdersCount: orderCount,
      actualCashCount: actualCashCount,
      notes: notes,
    );

    state = state.copyWith(
      clearActiveShift: true,
      shiftHistory: [closed, ...state.shiftHistory],
    );
    return closed;
  }
}

final shiftControllerProvider =
    StateNotifierProvider<ShiftController, ShiftState>((ref) {
      return ShiftController();
    });
