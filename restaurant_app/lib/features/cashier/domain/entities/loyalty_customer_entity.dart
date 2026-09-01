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

  /// Demo seeded loyal customers for fast phone lookup.
  static final List<LoyaltyCustomer> demoCustomers = [
    LoyaltyCustomer(
      id: 'cust-1',
      name: 'أحمد محمود العطار',
      phoneNumber: '01012345678',
      pointsBalance: 450, // 45 EGP
      tier: LoyaltyTier.gold,
      totalOrdersCount: 28,
      lastVisitAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    LoyaltyCustomer(
      id: 'cust-2',
      name: 'سارة عبد الرحمن',
      phoneNumber: '01198765432',
      pointsBalance: 820, // 82 EGP
      tier: LoyaltyTier.vip,
      totalOrdersCount: 64,
      lastVisitAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    LoyaltyCustomer(
      id: 'cust-3',
      name: 'طارق حسام الشريف',
      phoneNumber: '01234567890',
      pointsBalance: 180, // 18 EGP
      tier: LoyaltyTier.silver,
      totalOrdersCount: 12,
      lastVisitAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];
}
