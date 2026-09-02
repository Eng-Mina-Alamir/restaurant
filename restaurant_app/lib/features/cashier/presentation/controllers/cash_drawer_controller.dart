import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/service_locator.dart';
import '../../data/repositories/supabase_cashier_repository.dart';
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
  CashDrawerController([this._repository]) : super(const CashDrawerState()) {
    loadTransactions('SHIFT-${DateTime.now().year}${DateTime.now().month}${DateTime.now().day}');
  }

  final SupabaseCashierRepository? _repository;

  Future<void> loadTransactions(String shiftId) async {
    if (_repository == null) return;
    final result = await _repository.getTransactions(shiftId);
    result.when(
      onLeft: (_) {},
      onRight: (txs) {
        if (mounted) {
          state = state.copyWith(transactions: txs);
        }
      },
    );
  }

  /// Records a Pay-In (إيداع نقدية بالدرج).
  CashDrawerTransaction recordPayIn({
    required String shiftId,
    required double amount,
    required String reason,
    String? depositorName,
    String? managerPin,
  }) {
    final tx = CashDrawerTransaction(
      id: 'TX-IN-${DateTime.now().millisecondsSinceEpoch}',
      shiftId: shiftId,
      type: CashDrawerTransactionType.payIn,
      amount: amount,
      reason: reason,
      timestamp: DateTime.now(),
      recipientOrDepositor: depositorName,
      authorizedByManagerPin: managerPin,
    );

    state = state.copyWith(transactions: [tx, ...state.transactions]);
    _repository?.recordTransaction(tx);
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
    final tx = CashDrawerTransaction(
      id: 'TX-OUT-${DateTime.now().millisecondsSinceEpoch}',
      shiftId: shiftId,
      type: CashDrawerTransactionType.payOut,
      amount: amount,
      reason: reason,
      timestamp: DateTime.now(),
      recipientOrDepositor: recipientName,
      authorizedByManagerPin: managerPin,
    );

    state = state.copyWith(transactions: [tx, ...state.transactions]);
    _repository?.recordTransaction(tx);
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
      final repo = ref.watch(supabaseCashierRepositoryProvider);
      return CashDrawerController(repo);
    });

