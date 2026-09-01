import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/manager_dashboard/domain/entities/shift_entity.dart';

void main() {
  group('Shift Management & Blind Cash Discrepancy Tests', () {
    test('Calculates expected cash and variance correctly', () {
      final shift = ShiftEntity(
        id: 'shift-1001',
        cashierId: 'cashier-1',
        cashierName: 'محمود كاشير',
        openedAt: DateTime.now().subtract(const Duration(hours: 8)),
        openingCashFloat: 500.0, // Opening drawer float = 500 EGP
        cashSales: 3200.0, // Cash orders = 3200 EGP
        cardSales: 1500.0,
        walletSales: 300.0,
        actualCashCount: 3650.0, // Cashier counted 3650 EGP (Deficit of 50 EGP)
      );

      // Expected Cash = 500 + 3200 = 3700 EGP
      expect(shift.expectedCashInDrawer, equals(3700.0));
      // Discrepancy = 3650 - 3700 = -50 EGP (Deficit/عجز)
      expect(shift.cashDiscrepancy, equals(-50.0));
      expect(shift.totalSales, equals(5000.0));
    });

    test('Generates detailed Z-Report text summary with variance', () {
      final shift = ShiftEntity(
        id: 'shift-1002',
        cashierId: 'cashier-2',
        cashierName: 'سامح حسن',
        openedAt: DateTime(2026, 9, 1, 10, 0),
        closedAt: DateTime(2026, 9, 1, 18, 0),
        openingCashFloat: 1000.0,
        cashSales: 4000.0,
        cardSales: 2000.0,
        walletSales: 500.0,
        actualCashCount: 5000.0,
        status: ShiftStatus.closed,
      );

      final report = shift.generateZReportText();
      expect(report, contains('تقرير إقفال الوردية (Z-Report)'));
      expect(report, contains('سامح حسن'));
      expect(report, contains('shift-1002'));
    });
  });
}
