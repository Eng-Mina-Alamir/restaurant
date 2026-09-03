enum LoyaltyTier {
  bronze('برونزي 🥉'),
  silver('فضي 🥈'),
  gold('ذهبي 🥇'),
  vip('عميل مميز VIP 👑');

  final String labelAr;
  const LoyaltyTier(this.labelAr);
}

/// A restaurant customer with loyalty reward points.
class LoyaltyCustomer {
  const LoyaltyCustomer({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.pointsBalance,
    this.tier = LoyaltyTier.bronze,
    this.totalOrdersCount = 0,
    this.lastVisitAt,
  });

  final String id;
  final String name;
  final String phoneNumber;
  final int pointsBalance;
  final LoyaltyTier tier;
  final int totalOrdersCount;
  final DateTime? lastVisitAt;

  /// Conversion rate: 10 points = 1 EGP
  static const double kPointsToEgpRate = 0.10;

  double get pointsValueInEgp => pointsBalance * kPointsToEgpRate;

  /// Kept for API compatibility only and intentionally empty:
  /// customer lookup is Supabase-only (profiles + loyalty_accounts).
  /// Never add fake customers here.
  static final List<LoyaltyCustomer> demoCustomers = [];
}
