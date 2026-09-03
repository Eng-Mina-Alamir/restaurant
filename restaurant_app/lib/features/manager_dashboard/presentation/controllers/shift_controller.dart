import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/app_config.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../core/utils/logger.dart';
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
  ShiftController({SupabaseClient? supabase})
      : _supabase = supabase,
        super(
          ShiftState(
            activeShift: ShiftEntity(
              id: 'SHIFT-101',
              cashierId: '7db2b85c-3e6f-4468-9b70-2c787dac1b04',
              cashierName: 'حسام علي (كاشير النقطة)',
              openedAt: DateTime.now().subtract(const Duration(hours: 4)),
              openingCashFloat: 500.0,
              status: ShiftStatus.open,
            ),
            shiftHistory: [],
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
          .from('shift_reconciliations')
          .select()
          .order('shift_date', ascending: false);

      if (rows.isNotEmpty) {
        final List<ShiftEntity> history = [];
        for (final r in (rows as List)) {
          final m = Map<String, dynamic>.from(r as Map);
          history.add(
            ShiftEntity(
              id: m['id']?.toString() ?? '',
              cashierId: m['staff_id']?.toString() ?? '',
              cashierName: m['staff_name']?.toString() ?? '',
              openedAt: DateTime.tryParse(m['shift_date']?.toString() ?? '') ?? DateTime.now(),
              closedAt: m['settled_at'] != null ? DateTime.tryParse(m['settled_at'].toString()) : null,
              openingCashFloat: (m['opening_float'] as num?)?.toDouble() ?? 500.0,
              cashSales: (m['collected_cod'] as num?)?.toDouble() ?? 0.0,
              totalOrdersCount: (m['tables_served_count'] as num?)?.toInt() ?? 0,
              status: ShiftStatus.closed,
            ),
          );
        }
        state = state.copyWith(shiftHistory: history);
      }
    } catch (e) {
      AppLogger.warning('ShiftController loadFromSupabase error: $e');
    }
  }

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

    final client = _supabase;
    if (client != null) {
      Future.microtask(() async {
        try {
          await client.from('shift_reconciliations').insert({
            'id': closed.id,
            'restaurant_id': '1e08b47c-15be-4604-a913-431af7fbd54f',
            'staff_id': closed.cashierId.contains('-') && closed.cashierId.length >= 32
                ? closed.cashierId
                : '7db2b85c-3e6f-4468-9b70-2c787dac1b04',
            'staff_name': closed.cashierName,
            'role': 'cashier',
            'shift_date': closed.openedAt.toIso8601String(),
            'opening_float': closed.openingCashFloat,
            'collected_cod': closed.cashSales,
            'collected_tips': 0.0,
            'total_sales_volume': closed.cashSales + closed.cardSales + closed.walletSales,
            'tables_served_count': closed.totalOrdersCount,
            'completed_deliveries_count': 0,
            'is_settled': true,
            'settled_at': closed.closedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
            'created_at': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          AppLogger.warning('Shift closeShift sync error: $e');
        }
      });
    }

    return closed;
  }
}

final shiftControllerProvider =
    StateNotifierProvider<ShiftController, ShiftState>((ref) {
      final supabase = AppConfig.useSupabase ? ref.watch(supabaseClientProvider) : null;
      return ShiftController(supabase: supabase);
    });
