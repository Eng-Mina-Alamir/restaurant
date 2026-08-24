import 'dart:math' as math;

/// High-precision financial calculator for the restaurant system.
///
/// Ensures currency operations, tax calculations, discounts, and bill splitting
/// avoid floating point rounding anomalies and preserve exact penny/halala integrity.
abstract final class FinancialCalculator {
  FinancialCalculator._();

  /// Standard VAT rate in Saudi Arabia (15%).
  static const double defaultVatRate = 0.15;

  /// Rounds [amount] to standard 2 decimal places (halalas/cents) using half-up arithmetic
  /// with epsilon adjustment to eliminate binary floating-point representation drift.
  static double roundCurrency(double amount) {
    if (amount.isNaN || amount.isInfinite) return 0.0;
    const epsilon = 1e-9;
    final adjusted = amount >= 0 ? amount + epsilon : amount - epsilon;
    return (adjusted * 100).round() / 100.0;
  }

  /// Calculates VAT for [taxableAmount] at [rate] (default 15%), rounded to 2 decimals.
  static double calculateVat(
    double taxableAmount, {
    double rate = defaultVatRate,
  }) {
    if (taxableAmount <= 0) return 0.0;
    final rawVat = taxableAmount * rate;
    return roundCurrency(rawVat);
  }

  /// Computes a percentage discount on [subtotal], clamped by [maxDiscount] and [subtotal].
  static double calculatePercentageDiscount({
    required double subtotal,
    required double percentage,
    double? maxDiscount,
  }) {
    if (subtotal <= 0 || percentage <= 0) return 0.0;
    final clampedPercent = math.min(percentage, 100.0);
    double discount = subtotal * (clampedPercent / 100.0);
    if (maxDiscount != null && maxDiscount > 0 && discount > maxDiscount) {
      discount = maxDiscount;
    }
    if (discount > subtotal) {
      discount = subtotal;
    }
    return roundCurrency(discount);
  }

  /// Splits [totalAmount] across [numPersons] and returns an exact breakdown
  /// where the sum of all portions is guaranteed to equal [totalAmount].
  ///
  /// Any remainder halalas/cents (e.g. 100.00 / 3 -> 33.33 * 3 = 99.99 with 0.01 remainder)
  /// are distributed 1 cent per person to the leading persons.
  static List<double> splitBillDetailed(double totalAmount, int numPersons) {
    if (numPersons <= 0 || totalAmount <= 0) {
      return [roundCurrency(math.max(0.0, totalAmount))];
    }
    if (numPersons == 1) {
      return [roundCurrency(totalAmount)];
    }

    final totalCents = (totalAmount * 100).round();
    final baseCents = totalCents ~/ numPersons;
    final remainderCents = totalCents % numPersons;

    final shares = <double>[];
    for (int i = 0; i < numPersons; i++) {
      final centsForThisPerson = baseCents + (i < remainderCents ? 1 : 0);
      shares.add(centsForThisPerson / 100.0);
    }
    return shares;
  }

  /// Computes the uniform per-person share (simple division), clamped safely.
  static double splitTotal(double totalAmount, int numPersons) {
    if (numPersons <= 0) return roundCurrency(totalAmount);
    return roundCurrency(totalAmount / numPersons);
  }
}
