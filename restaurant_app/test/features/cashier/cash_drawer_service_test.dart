import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/cashier/domain/entities/cash_drawer_transaction_entity.dart';
import 'package:restaurant_app/features/cashier/domain/entities/order_refund_entity.dart';
import 'package:restaurant_app/features/cashier/domain/services/cash_drawer_service.dart';
import 'package:restaurant_app/features/cashier/presentation/controllers/cash_drawer_controller.dart';

void main() {
  group('CashDrawerService & CashDrawerController', () {
    test('calculateExpectedDrawerCash properly calculates float + sales + payIns - payOuts - refunds', () {
      final transactions = [
        CashDrawerTransaction(
          id: '1',
          shiftId: 'shift-1',
          type: CashDrawerTransactionType.payIn,
          amount: 200.0,
          reason: 'فكة إضافية من الخزينة',
          timestamp: DateTime.now(),
        ),
        CashDrawerTransaction(
          id: '2',
          shiftId: 'shift-1',
          type: CashDrawerTransactionType.payOut,
          amount: 75.0,
          reason: 'شراء خضار طازج',
          timestamp: DateTime.now(),
        ),
      ];

      final refunds = [
        OrderRefundRecord(
          id: 'r1',
          originalOrderId: 'ord-100',
          refundAmount: 50.0,
          refundMethod: PaymentMethod.cash,
          reason: 'إلغاء وجبة',
          refundedAt: DateTime.now(),
        ),
      ];

      // Opening Float = 500, Cash Sales = 1500, Pay-In = 200, Pay-Out = 75, Refund = 50
      // Expected = 500 + 1500 + 200 - 75 - 50 = 2075.0
      final expectedCash = CashDrawerService.calculateExpectedDrawerCash(
        openingFloat: 500.0,
        cashSales: 1500.0,
        drawerTransactions: transactions,
        refunds: refunds,
      );

      expect(expectedCash, equals(2075.0));

      final discrepancy = CashDrawerService.calculateCashDiscrepancy(
        actualCashCounted: 2075.0,
        expectedCash: expectedCash,
      );
      expect(discrepancy, equals(0.0));
    });

    test('CashDrawerController state transitions and recordings', () {
      final controller = CashDrawerController();

      controller.recordPayIn(
        shiftId: 's1',
        amount: 300.0,
        reason: 'عهدة فكة',
      );

      expect(controller.state.totalPayIns, equals(300.0));
      expect(controller.state.transactions.length, equals(1));

      controller.recordPayOut(
        shiftId: 's1',
        amount: 120.0,
        reason: 'مصروفات نظافة',
      );

      expect(controller.state.totalPayOuts, equals(120.0));
      expect(controller.state.transactions.length, equals(2));

      final net = controller.state.calculateNetDrawerCash(
        openingFloat: 500.0,
        cashSales: 1000.0,
      );
      // 500 + 1000 + 300 - 120 = 1680.0
      expect(net, equals(1680.0));
    });
  });
}
