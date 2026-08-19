import 'entities/cart_item.dart';

/// Flat VAT percentage applied on the subtotal.
///
/// Kept as a single source of truth so the cart totals and the final order
/// always agree. (15% is a common regional VAT.)
const double kTaxRate = 0.15;

/// Derived money figures for a cart.
///
/// Pure value object — never mutates the cart itself. The calculation lives in
/// the domain layer so it can be unit-tested without Flutter.
class CartTotals {
  const CartTotals({
    required this.subtotal,
    this.discountAmount = 0.0,
    required this.taxAmount,
    required this.totalAmount,
  });

  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;

  /// Computes the totals for [items] with optional discount.
  factory CartTotals.fromItems(
    Iterable<CartItem> items, {
    double discountAmount = 0.0,
  }) {
    final subtotal = items.fold<double>(0, (sum, item) => sum + item.linePrice);
    final effectiveSubtotal =
        (subtotal - discountAmount).clamp(0.0, double.infinity);
    final taxAmount = effectiveSubtotal * kTaxRate;
    return CartTotals(
      subtotal: subtotal,
      discountAmount: discountAmount,
      taxAmount: taxAmount,
      totalAmount: effectiveSubtotal + taxAmount,
    );
  }

  @override
  String toString() =>
      'CartTotals(subtotal: $subtotal, discount: $discountAmount, '
      'taxAmount: $taxAmount, totalAmount: $totalAmount)';
}

