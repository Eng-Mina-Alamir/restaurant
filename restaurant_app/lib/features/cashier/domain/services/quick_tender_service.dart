/// Pure domain service calculating change due and quick suggested cash bills for cashier POS.
abstract final class QuickTenderService {
  QuickTenderService._();

  /// Egyptian Currency standard bills
  static const List<double> standardBills = [50.0, 100.0, 200.0, 500.0];

  /// Computes recommended quick tender amounts based on [totalDue].
  /// e.g. for totalDue = 340:
  /// - Exact: 340
  /// - Next 50: 350
  /// - Next 100: 400
  /// - 500 Bill: 500
  static List<double> calculateSuggestedTenders(double totalDue) {
    if (totalDue <= 0) return [50.0, 100.0, 200.0];

    final Set<double> suggestions = {};

    // 1. Exact amount
    suggestions.add(totalDue);

    // 2. Next nearest 50 EGP
    final next50 = (totalDue / 50).ceil() * 50.0;
    if (next50 > totalDue) {
      suggestions.add(next50);
    }

    // 3. Next nearest 100 EGP
    final next100 = (totalDue / 100).ceil() * 100.0;
    if (next100 > totalDue && next100 != next50) {
      suggestions.add(next100);
    }

    // 4. Standard bills higher than totalDue
    for (final bill in standardBills) {
      if (bill >= totalDue) {
        suggestions.add(bill);
      }
    }

    final sorted = suggestions.toList()..sort();
    return sorted.take(4).toList();
  }

  /// Calculates change due for the customer: tendered - totalDue.
  /// Returns 0.0 if tendered is less than totalDue.
  static double calculateChangeDue({
    required double totalDue,
    required double tenderedAmount,
  }) {
    if (tenderedAmount < totalDue) return 0.0;
    final change = tenderedAmount - totalDue;
    return double.parse(change.toStringAsFixed(2));
  }

  /// Checks whether the tendered amount is sufficient to settle the bill.
  static bool isTenderSufficient({
    required double totalDue,
    required double tenderedAmount,
  }) {
    return (tenderedAmount + 0.05) >= totalDue;
  }
}
