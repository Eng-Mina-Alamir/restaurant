import '../entities/cash_drawer_transaction_entity.dart';
import '../entities/order_refund_entity.dart';

/// Pure domain service calculating net cash drawer balance and shift cash flow.
abstract final class CashDrawerService {
  CashDrawerService._();

  /// Calculates total Pay-Ins (إيداعات إضافية بالدرج).
  static double calculateTotalPayIns(List<CashDrawerTransaction> transactions) {
    return transactions
        .where((t) => t.type == CashDrawerTransactionType.payIn)
        .fold<double>(0.0, (acc, t) => acc + t.amount);
  }

  /// Calculates total Pay-Outs (مصروفات وسحوبات نثرية من الدرج).
  static double calculateTotalPayOuts(List<CashDrawerTransaction> transactions) {
    return transactions
        .where((t) => t.type == CashDrawerTransactionType.payOut)
        .fold<double>(0.0, (acc, t) => acc + t.amount);
  }

  /// Calculates total cash refunds.
  static double calculateTotalCashRefunds(List<OrderRefundRecord> refunds) {
    return refunds.fold<double>(0.0, (acc, r) => acc + r.refundAmount);
  }

  /// Calculates the mathematically expected cash in the drawer at any given moment:
  /// Opening Float + Cash Sales + Pay-Ins - Pay-Outs - Cash Refunds.
  static double calculateExpectedDrawerCash({
    required double openingFloat,
    required double cashSales,
    required List<CashDrawerTransaction> drawerTransactions,
    List<OrderRefundRecord> refunds = const [],
  }) {
    final payIns = calculateTotalPayIns(drawerTransactions);
    final payOuts = calculateTotalPayOuts(drawerTransactions);
    final cashRefunds = calculateTotalCashRefunds(refunds);

    final expected = (openingFloat + cashSales + payIns) - (payOuts + cashRefunds);
    return double.parse(expected.toStringAsFixed(2));
  }

  /// Calculates cash discrepancy between physical cash counted by the cashier and expected cash.
  static double calculateCashDiscrepancy({
    required double actualCashCounted,
    required double expectedCash,
  }) {
    final diff = actualCashCounted - expectedCash;
    return double.parse(diff.toStringAsFixed(2));
  }
}
