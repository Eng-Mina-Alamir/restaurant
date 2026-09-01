import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/driver_wallet_entity.dart';

final driverWalletControllerProvider =
    StateNotifierProvider<DriverWalletController, DriverWalletEntity>((ref) {
  return DriverWalletController();
});

class DriverWalletController extends StateNotifier<DriverWalletEntity> {
  DriverWalletController() : super(const DriverWalletEntity());

  /// Sets opening cash float given by cashier at shift start
  void setOpeningFloat(double amount) {
    state = state.copyWith(openingFloat: amount, isSettled: false);
  }

  /// Records cash collected on delivery of a COD order
  void recordCodCollection(
    double codAmount, {
    double tip = 0.0,
    double commission = 20.0,
  }) {
    state = state.copyWith(
      collectedCod: state.collectedCod + codAmount,
      collectedTips: state.collectedTips + tip,
      earnedCommission: state.earnedCommission + commission,
      completedDeliveriesCount: state.completedDeliveriesCount + 1,
      isSettled: false,
    );
  }

  /// Records a completed prepaid (Visa/Online) order (no COD added, but commission & tips added)
  void recordPrepaidDelivery({
    double tip = 0.0,
    double commission = 20.0,
  }) {
    state = state.copyWith(
      collectedTips: state.collectedTips + tip,
      earnedCommission: state.earnedCommission + commission,
      completedDeliveriesCount: state.completedDeliveriesCount + 1,
      isSettled: false,
    );
  }

  /// Settles shift cash remittance with cashier at the end of the day
  void settleShift() {
    state = state.copyWith(
      isSettled: true,
      lastSettledAt: DateTime.now(),
    );
  }

  /// Resets and starts a brand new shift
  void startNewShift({double openingFloat = 500.0}) {
    state = DriverWalletEntity(
      openingFloat: openingFloat,
      collectedCod: 0.0,
      collectedTips: 0.0,
      earnedCommission: 0.0,
      completedDeliveriesCount: 0,
      isSettled: false,
    );
  }
}
