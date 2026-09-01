import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/delivery/domain/entities/driver_wallet_entity.dart';
import 'package:restaurant_app/features/delivery/domain/services/driver_quick_action_service.dart';
import 'package:restaurant_app/features/delivery/presentation/controllers/driver_wallet_controller.dart';

void main() {
  group('Driver Wallet & COD Calculations Tests', () {
    test('Initializes with default float and correctly computes cash in hand', () {
      const wallet = DriverWalletEntity(
        openingFloat: 500.0,
        collectedCod: 0.0,
        collectedTips: 0.0,
        earnedCommission: 0.0,
      );

      expect(wallet.totalCashInHand, 500.0);
      expect(wallet.remittanceDueToCashier, 500.0);
      expect(wallet.totalDriverEarnings, 0.0);
    });

    test('Correctly aggregates COD cash, tips and commission', () {
      final controller = DriverWalletController();
      controller.setOpeningFloat(500.0);

      // 1st order: 250 EGP COD + 15 EGP tip + 20 EGP commission
      controller.recordCodCollection(250.0, tip: 15.0, commission: 20.0);

      expect(controller.state.openingFloat, 500.0);
      expect(controller.state.collectedCod, 250.0);
      expect(controller.state.collectedTips, 15.0);
      expect(controller.state.earnedCommission, 20.0);
      expect(controller.state.completedDeliveriesCount, 1);
      expect(controller.state.totalCashInHand, 500.0 + 250.0 + 15.0); // 765.0
      expect(controller.state.remittanceDueToCashier, 750.0); // 500 + 250
      expect(controller.state.totalDriverEarnings, 35.0); // 20 + 15

      // 2nd order: Prepaid (Visa) -> 0 COD, 20 EGP commission, 10 EGP tip
      controller.recordPrepaidDelivery(tip: 10.0, commission: 20.0);
      expect(controller.state.completedDeliveriesCount, 2);
      expect(controller.state.collectedCod, 250.0);
      expect(controller.state.collectedTips, 25.0);
      expect(controller.state.earnedCommission, 40.0);
      expect(controller.state.totalCashInHand, 500.0 + 250.0 + 25.0); // 775.0
      expect(controller.state.totalDriverEarnings, 65.0);
    });

    test('Settles shift and resets remittance liability', () {
      final controller = DriverWalletController();
      controller.setOpeningFloat(500.0);
      controller.recordCodCollection(300.0, tip: 20.0, commission: 20.0);

      expect(controller.state.isSettled, false);
      expect(controller.state.remittanceDueToCashier, 800.0);

      controller.settleShift();
      expect(controller.state.isSettled, true);
      expect(controller.state.remittanceDueToCashier, 0.0);
      expect(controller.state.totalCashInHand, 0.0);
      expect(controller.state.lastSettledAt, isNotNull);
    });
  });

  group('Rider Change Calculator Tests', () {
    test('Calculates exact change due when cash is greater than total', () {
      final result = DriverQuickActionService.calculateChange(
        orderTotal: 285.0,
        cashReceived: 500.0,
      );

      expect(result.isInsufficient, false);
      expect(result.isExact, false);
      expect(result.changeDue, 215.0);
      expect(result.shortfall, 0.0);
    });

    test('Detects exact cash payment with zero change', () {
      final result = DriverQuickActionService.calculateChange(
        orderTotal: 250.0,
        cashReceived: 250.0,
      );

      expect(result.isInsufficient, false);
      expect(result.isExact, true);
      expect(result.changeDue, 0.0);
    });

    test('Detects insufficient cash shortfall correctly', () {
      final result = DriverQuickActionService.calculateChange(
        orderTotal: 300.0,
        cashReceived: 200.0,
      );

      expect(result.isInsufficient, true);
      expect(result.isExact, false);
      expect(result.changeDue, 0.0);
      expect(result.shortfall, 100.0);
    });
  });
}
