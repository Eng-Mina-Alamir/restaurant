import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/enums.dart';
import '../../domain/entities/cashier_discount_entity.dart';
import '../../domain/entities/loyalty_customer_entity.dart';
import '../../domain/entities/split_tender_payment_entity.dart';

/// State of an active POS transaction at the Cashier counter.
class CashierPOSState {
  const CashierPOSState({
    this.selectedDiscount,
    this.linkedLoyaltyCustomer,
    this.redeemedPoints = 0,
    this.redeemedPointsDiscountAmount = 0.0,
    this.splitTenderResult,
    this.tenderedCash = 0.0,
    this.orderType = OrderType.takeaway,
    this.selectedTableNumber,
  });

  final CashierDiscount? selectedDiscount;
  final LoyaltyCustomer? linkedLoyaltyCustomer;
  final int redeemedPoints;
  final double redeemedPointsDiscountAmount;
  final SplitTenderResult? splitTenderResult;
  final double tenderedCash;
  final OrderType orderType;
  final int? selectedTableNumber;

  /// Calculates total monetary discount (preset/comp discount + loyalty redeemed points discount).
  double calculateTotalDiscount(double subtotal) {
    double total = 0.0;
    if (selectedDiscount != null) {
      total += selectedDiscount!.calculateDiscountAmount(subtotal);
    }
    total += redeemedPointsDiscountAmount;
    return total.clamp(0.0, subtotal);
  }

  CashierPOSState copyWith({
    CashierDiscount? selectedDiscount,
    LoyaltyCustomer? linkedLoyaltyCustomer,
    int? redeemedPoints,
    double? redeemedPointsDiscountAmount,
    SplitTenderResult? splitTenderResult,
    double? tenderedCash,
    OrderType? orderType,
    int? selectedTableNumber,
    bool clearDiscount = false,
    bool clearCustomer = false,
    bool clearSplitTender = false,
    bool clearTable = false,
  }) {
    return CashierPOSState(
      selectedDiscount: clearDiscount ? null : (selectedDiscount ?? this.selectedDiscount),
      linkedLoyaltyCustomer: clearCustomer ? null : (linkedLoyaltyCustomer ?? this.linkedLoyaltyCustomer),
      redeemedPoints: clearCustomer ? 0 : (redeemedPoints ?? this.redeemedPoints),
      redeemedPointsDiscountAmount:
          clearCustomer ? 0.0 : (redeemedPointsDiscountAmount ?? this.redeemedPointsDiscountAmount),
      splitTenderResult: clearSplitTender ? null : (splitTenderResult ?? this.splitTenderResult),
      tenderedCash: tenderedCash ?? this.tenderedCash,
      orderType: orderType ?? this.orderType,
      selectedTableNumber: clearTable ? null : (selectedTableNumber ?? this.selectedTableNumber),
    );
  }
}

/// Controller managing discounts, customer loyalty linkage, and tender calculations for POS checkout.
class CashierPOSController extends StateNotifier<CashierPOSState> {
  CashierPOSController() : super(const CashierPOSState());

  /// Updates the order type (dine-in, takeaway, delivery).
  void setOrderType(OrderType type) {
    state = state.copyWith(orderType: type);
  }

  /// Sets or clears the table number for dine-in checkout.
  void setSelectedTableNumber(int? tableNumber) {
    if (tableNumber == null) {
      state = state.copyWith(clearTable: true);
    } else {
      state = state.copyWith(selectedTableNumber: tableNumber);
    }
  }

  /// Applies a discount to the active checkout.
  void applyDiscount(CashierDiscount discount) {
    state = state.copyWith(selectedDiscount: discount);
  }

  /// Removes any applied discount.
  void removeDiscount() {
    state = state.copyWith(clearDiscount: true);
  }

  /// Links a loyalty customer to the active checkout.
  void linkCustomer(LoyaltyCustomer customer) {
    state = state.copyWith(
      linkedLoyaltyCustomer: customer,
      redeemedPoints: 0,
      redeemedPointsDiscountAmount: 0.0,
    );
  }

  /// Unlinks loyalty customer.
  void unlinkCustomer() {
    state = state.copyWith(clearCustomer: true);
  }

  /// Redeems loyalty points for a direct cash discount on the active bill.
  void redeemCustomerPoints(int points) {
    final customer = state.linkedLoyaltyCustomer;
    if (customer == null || points <= 0) return;

    final actualPoints = points.clamp(0, customer.pointsBalance);
    final discountVal = actualPoints * LoyaltyCustomer.kPointsToEgpRate;

    state = state.copyWith(
      redeemedPoints: actualPoints,
      redeemedPointsDiscountAmount: discountVal,
    );
  }

  /// Sets the tendered cash amount for quick change calculation.
  void setTenderedCash(double amount) {
    state = state.copyWith(tenderedCash: amount);
  }

  /// Updates split-tender payment progress.
  void updateSplitTender(SplitTenderResult result) {
    state = state.copyWith(splitTenderResult: result);
  }

  /// Resets POS transaction state back to clean defaults for the next order.
  void reset() {
    state = const CashierPOSState();
  }
}

/// Riverpod provider for [CashierPOSController].
final cashierPOSControllerProvider =
    StateNotifierProvider<CashierPOSController, CashierPOSState>((ref) {
      return CashierPOSController();
    });
