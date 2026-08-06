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
    required this.taxAmount,
    required this.totalAmount,
  });

  final double subtotal;
  final double taxAmount;
  final double totalAmount;

  /// Computes the totals for [items].
  factory CartTotals.fromItems(Iterable<CartItem> items) {
    final subtotal = items.fold<double>(0, (sum, item) => sum + item.linePrice);
    final taxAmount = subtotal * kTaxRate;
    return CartTotals(
      subtotal: subtotal,
      taxAmount: taxAmount,
      totalAmount: subtotal + taxAmount,
    );
  }

  @override
  String toString() =>
      'CartTotals(subtotal: $subtotal, taxAmount: $taxAmount, '
      'totalAmount: $totalAmount)';
}
