import '../../../../core/domain/enums.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../../../orders/domain/entities/order_item.dart';
import '../entities/split_bill_entity.dart';

/// Pure domain service providing high-precision calculation and integrity checks
/// for restaurant bill splitting across multiple guests, seats, and payment methods.
abstract final class BillSplittingService {
  BillSplittingService._();

  /// Calculates an exact equal split among [guestCount] guests.
  /// Any rounding cent fractions (e.g. 100 / 3 = 33.333...) are balanced onto the first share
  /// so the sum of parts is mathematically 100% equal to [totalBill].
  static SplitBillResult calculateEqualSplit({
    required String orderId,
    required double totalBill,
    required int guestCount,
    double tipAmount = 0.0,
  }) {
    final validGuests = guestCount > 0 ? guestCount : 1;
    final totalWithTip = totalBill + tipAmount;

    // Base share rounded to 2 decimal places
    final rawShare = (totalWithTip / validGuests);
    final roundedShare = (rawShare * 100).floorToDouble() / 100;

    final tipPerGuest = tipAmount > 0 ? (tipAmount / validGuests) : 0.0;
    final baseSubtotalPerGuest = (totalBill / validGuests);

    final List<SplitBillShare> shares = [];
    double accumulated = 0.0;

    for (int i = 1; i <= validGuests; i++) {
      final isLast = i == validGuests;
      final currentShareAmount =
          isLast
              ? (totalWithTip - accumulated) // absorbs leftover cents
              : roundedShare;

      accumulated += currentShareAmount;

      shares.add(
        SplitBillShare(
          shareIndex: i,
          guestLabel: 'الضيف #$i',
          subtotal: baseSubtotalPerGuest,
          taxAmount: 0.0,
          serviceAmount: 0.0,
          tipAmount: tipPerGuest,
          totalAmount: double.parse(currentShareAmount.toStringAsFixed(2)),
          paymentMethod: PaymentMethod.cash,
          isPaid: false,
        ),
      );
    }

    return SplitBillResult(
      orderId: orderId,
      originalTotal: totalWithTip,
      splitType: SplitBillType.equal,
      shares: shares,
    );
  }

  /// Calculates a seat-based or item-based bill split from [orderItems].
  static SplitBillResult calculateSeatOrItemSplit({
    required String orderId,
    required List<OrderItem> orderItems,
    required int totalGuests,
    double taxRate = 0.14,
    double serviceRate = 0.12,
  }) {
    final count = totalGuests > 0 ? totalGuests : 1;

    // Group items by seat or distribute evenly
    final Map<int, List<OrderItem>> itemsBySeat = {};
    for (int i = 1; i <= count; i++) {
      itemsBySeat[i] = [];
    }

    for (int i = 0; i < orderItems.length; i++) {
      final item = orderItems[i];
      final targetSeat = (i % count) + 1;
      itemsBySeat[targetSeat]?.add(item);
    }

    final List<SplitBillShare> shares = [];
    double overallTotal = 0.0;

    itemsBySeat.forEach((seatNum, items) {
      final seatSubtotal = items.fold<double>(
        0.0,
        (acc, it) => acc + it.lineTotal,
      );
      final tax = seatSubtotal * taxRate;
      final service = seatSubtotal * serviceRate;
      final seatTotal = double.parse(
        (seatSubtotal + tax + service).toStringAsFixed(2),
      );

      overallTotal += seatTotal;

      shares.add(
        SplitBillShare(
          shareIndex: seatNum,
          guestLabel: 'المقعد #$seatNum',
          subtotal: double.parse(seatSubtotal.toStringAsFixed(2)),
          taxAmount: double.parse(tax.toStringAsFixed(2)),
          serviceAmount: double.parse(service.toStringAsFixed(2)),
          tipAmount: 0.0,
          totalAmount: seatTotal,
          seatNumber: seatNum,
          itemNames:
              items.map((e) => '${e.menuItem.name} × ${e.quantity}').toList(),
          paymentMethod: PaymentMethod.cash,
          isPaid: false,
        ),
      );
    });

    return SplitBillResult(
      orderId: orderId,
      originalTotal: double.parse(overallTotal.toStringAsFixed(2)),
      splitType: SplitBillType.bySeat,
      shares: shares,
    );
  }

  /// Calculates a seat split directly from active [CartItem] list during waiter intake.
  static SplitBillResult calculateFromCartItems({
    required String orderId,
    required List<CartItem> cartItems,
    required int guestCount,
    double taxRate = 0.14,
    double serviceRate = 0.12,
  }) {
    final count = guestCount > 0 ? guestCount : 1;
    final Map<int, List<CartItem>> itemsBySeat = {};
    for (int i = 1; i <= count; i++) {
      itemsBySeat[i] = [];
    }

    for (int i = 0; i < cartItems.length; i++) {
      final item = cartItems[i];
      final targetSeat = (i % count) + 1;
      itemsBySeat[targetSeat]?.add(item);
    }

    final List<SplitBillShare> shares = [];
    double overallTotal = 0.0;

    itemsBySeat.forEach((seatNum, items) {
      final seatSubtotal = items.fold<double>(
        0.0,
        (acc, it) => acc + it.linePrice,
      );
      final tax = seatSubtotal * taxRate;
      final service = seatSubtotal * serviceRate;
      final seatTotal = double.parse(
        (seatSubtotal + tax + service).toStringAsFixed(2),
      );

      overallTotal += seatTotal;

      shares.add(
        SplitBillShare(
          shareIndex: seatNum,
          guestLabel: 'الضيف / المقعد #$seatNum',
          subtotal: double.parse(seatSubtotal.toStringAsFixed(2)),
          taxAmount: double.parse(tax.toStringAsFixed(2)),
          serviceAmount: double.parse(service.toStringAsFixed(2)),
          tipAmount: 0.0,
          totalAmount: seatTotal,
          seatNumber: seatNum,
          itemNames:
              items.map((e) => '${e.menuItem.name} × ${e.quantity}').toList(),
          paymentMethod: PaymentMethod.cash,
          isPaid: false,
        ),
      );
    });

    return SplitBillResult(
      orderId: orderId,
      originalTotal: double.parse(overallTotal.toStringAsFixed(2)),
      splitType: SplitBillType.bySeat,
      shares: shares,
    );
  }

  /// Verifies that the sum of all individual shares equals the expected bill total within 0.05 tolerance.
  static bool validateSharesIntegrity(
    List<SplitBillShare> shares,
    double expectedTotal,
  ) {
    if (shares.isEmpty) return false;
    final sum = shares.fold<double>(0.0, (acc, s) => acc + s.totalAmount);
    return (sum - expectedTotal).abs() <= 0.05;
  }
}
