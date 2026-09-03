import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/app_config.dart';
import '../../../../config/supabase_config.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../core/utils/financial_calculator.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/cash_drawer_transaction_entity.dart';
import '../../domain/entities/order_refund_entity.dart';
import '../../domain/services/cash_drawer_service.dart';

/// State of the cash drawer movements and transactions for the active cashier shift.
class CashDrawerState {
  const CashDrawerState({
    this.transactions = const [],
    this.refunds = const [],
  });

  final List<CashDrawerTransaction> transactions;
  final List<OrderRefundRecord> refunds;

  double get totalPayIns => CashDrawerService.calculateTotalPayIns(transactions);

  double get totalPayOuts => CashDrawerService.calculateTotalPayOuts(transactions);

  double get totalRefunds => CashDrawerService.calculateTotalCashRefunds(refunds);

  double calculateNetDrawerCash({
    required double openingFloat,
    required double cashSales,
  }) {
    return CashDrawerService.calculateExpectedDrawerCash(
      openingFloat: openingFloat,
      cashSales: cashSales,
      drawerTransactions: transactions,
      refunds: refunds,
    );
  }

  CashDrawerState copyWith({
    List<CashDrawerTransaction>? transactions,
    List<OrderRefundRecord>? refunds,
  }) {
    return CashDrawerState(
      transactions: transactions ?? this.transactions,
      refunds: refunds ?? this.refunds,
    );
  }
}

/// Controller managing cash drawer movements (Pay-In, Pay-Out, and Refunds).
class CashDrawerController extends StateNotifier<CashDrawerState> {
  CashDrawerController({SupabaseClient? supabase})
      : _supabase = supabase,
        super(const CashDrawerState()) {
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
          .from('cash_drawer_transactions')
          .select()
          .order('created_at', ascending: false);

      if (rows.isNotEmpty) {
        final List<CashDrawerTransaction> list = [];
        for (final r in (rows as List)) {
          final m = Map<String, dynamic>.from(r as Map);
          final typeStr = m['type']?.toString() ?? 'payIn';
          final type = typeStr == 'payOut'
              ? CashDrawerTransactionType.payOut
              : CashDrawerTransactionType.payIn;

          list.add(
            CashDrawerTransaction(
              id: m['id']?.toString() ?? '',
              shiftId: m['shift_id']?.toString() ?? 'SHIFT-1',
              type: type,
              amount: (m['amount'] as num?)?.toDouble() ?? 0.0,
              reason: m['reason']?.toString() ?? '',
              timestamp: DateTime.tryParse(m['created_at']?.toString() ?? '') ?? DateTime.now(),
              recipientOrDepositor: m['recipient_or_depositor']?.toString(),
              authorizedByManagerPin: m['authorized_by_manager_pin']?.toString(),
            ),
          );
        }
        state = state.copyWith(transactions: list);
      }
    } catch (e) {
      AppLogger.warning('CashDrawerController loadFromSupabase error: $e');
    }
  }

  /// Records a Pay-In (إيداع نقدية بالدرج).
  CashDrawerTransaction recordPayIn({
    required String shiftId,
    required double amount,
    required String reason,
    String? depositorName,
    String? managerPin,
  }) {
    final safeAmount = FinancialCalculator.roundCurrency(amount.abs());
    final tx = CashDrawerTransaction(
      id: 'TX-IN-${DateTime.now().millisecondsSinceEpoch}',
      shiftId: shiftId,
      type: CashDrawerTransactionType.payIn,
      amount: safeAmount,
      reason: reason,
      timestamp: DateTime.now(),
      recipientOrDepositor: depositorName,
      authorizedByManagerPin: managerPin,
    );

    state = state.copyWith(transactions: [tx, ...state.transactions]);

    final client = _supabase;
    if (client != null) {
      Future.microtask(() async {
        try {
          await client.from('cash_drawer_transactions').insert({
            'restaurant_id': SupabaseConfig.defaultRestaurantId,
            'shift_id': shiftId,
            'type': 'payIn',
            'amount': safeAmount,
            'reason': reason,
            'recipient_or_depositor': depositorName,
            'authorized_by_manager_pin': managerPin,
            'created_at': tx.timestamp.toIso8601String(),
          });
        } catch (e) {
          AppLogger.warning('CashDrawer recordPayIn sync error: $e');
        }
      });
    }

    return tx;
  }

  /// Records a Pay-Out (سحب مصروفات نثرية أو مشتريات طارئة).
  CashDrawerTransaction recordPayOut({
    required String shiftId,
    required double amount,
    required String reason,
    String? recipientName,
    String? managerPin,
  }) {
    final safeAmount = FinancialCalculator.roundCurrency(amount.abs());
    final tx = CashDrawerTransaction(
      id: 'TX-OUT-${DateTime.now().millisecondsSinceEpoch}',
      shiftId: shiftId,
      type: CashDrawerTransactionType.payOut,
      amount: safeAmount,
      reason: reason,
      timestamp: DateTime.now(),
      recipientOrDepositor: recipientName,
      authorizedByManagerPin: managerPin,
    );

    state = state.copyWith(transactions: [tx, ...state.transactions]);

    final client = _supabase;
    if (client != null) {
      Future.microtask(() async {
        try {
          await client.from('cash_drawer_transactions').insert({
            'restaurant_id': SupabaseConfig.defaultRestaurantId,
            'shift_id': shiftId,
            'type': 'payOut',
            'amount': safeAmount,
            'reason': reason,
            'recipient_or_depositor': recipientName,
            'authorized_by_manager_pin': managerPin,
            'created_at': tx.timestamp.toIso8601String(),
          });
        } catch (e) {
          AppLogger.warning('CashDrawer recordPayOut sync error: $e');
        }
      });
    }

    return tx;
  }

  /// Records a customer refund transaction.
  OrderRefundRecord recordRefund(OrderRefundRecord refund) {
    state = state.copyWith(refunds: [refund, ...state.refunds]);
    return refund;
  }

  /// Clears transactions on shift reset.
  void clearShiftTransactions() {
    state = const CashDrawerState();
  }
}

/// Riverpod provider for [CashDrawerController].
final cashDrawerControllerProvider =
    StateNotifierProvider<CashDrawerController, CashDrawerState>((ref) {
      final supabase = AppConfig.useSupabase ? ref.watch(supabaseClientProvider) : null;
      return CashDrawerController(supabase: supabase);
    });
