import 'package:flutter/material.dart';

/// Loyalty tiers with points threshold, reward multipliers and theme colors.
enum LoyaltyTier {
  bronze('برونزي', 'Bronze', 0, 1.0, Color(0xFFCD7F32)),
  silver('فضي', 'Silver', 500, 1.25, Color(0xFFC0C0C0)),
  gold('ذهبي', 'Gold', 1500, 1.5, Color(0xFFFFD700)),
  platinum('بلاتيني', 'Platinum', 3000, 2.0, Color(0xFFE5E4E2));

  final String labelAr;
  final String labelEn;
  final int minPoints;
  final double multiplier;
  final Color color;

  const LoyaltyTier(
    this.labelAr,
    this.labelEn,
    this.minPoints,
    this.multiplier,
    this.color,
  );

  static LoyaltyTier fromPoints(int points) {
    if (points >= platinum.minPoints) return platinum;
    if (points >= gold.minPoints) return gold;
    if (points >= silver.minPoints) return silver;
    return bronze;
  }

  LoyaltyTier? get nextTier {
    switch (this) {
      case LoyaltyTier.bronze:
        return LoyaltyTier.silver;
      case LoyaltyTier.silver:
        return LoyaltyTier.gold;
      case LoyaltyTier.gold:
        return LoyaltyTier.platinum;
      case LoyaltyTier.platinum:
        return null;
    }
  }
}

enum PointsTransactionType {
  earn('اكتساب نقاط'),
  redeem('استبدال نقاط'),
  bonus('مكافأة ترحيبية');

  final String labelAr;
  const PointsTransactionType(this.labelAr);
}

class PointsTransaction {
  final String id;
  final int points;
  final String description;
  final DateTime createdAt;
  final PointsTransactionType type;

  const PointsTransaction({
    required this.id,
    required this.points,
    required this.description,
    required this.createdAt,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'points': points,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
        'type': type.name,
      };

  factory PointsTransaction.fromJson(Map<String, dynamic> json) =>
      PointsTransaction(
        id: json['id'] as String,
        points: json['points'] as int,
        description: json['description'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        type: PointsTransactionType.values.byName(json['type'] as String),
      );
}

class LoyaltyReward {
  final String id;
  final String title;
  final String description;
  final int pointsCost;
  final double discountAmount;
  final double minOrderAmount;
  final String iconName;

  const LoyaltyReward({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsCost,
    required this.discountAmount,
    this.minOrderAmount = 0.0,
    this.iconName = 'card_giftcard',
  });
}

class LoyaltyAccount {
  final String userId;
  final int currentPoints;
  final int lifetimePoints;
  final LoyaltyTier tier;
  final List<PointsTransaction> transactions;

  const LoyaltyAccount({
    required this.userId,
    required this.currentPoints,
    required this.lifetimePoints,
    required this.tier,
    required this.transactions,
  });

  LoyaltyAccount copyWith({
    String? userId,
    int? currentPoints,
    int? lifetimePoints,
    LoyaltyTier? tier,
    List<PointsTransaction>? transactions,
  }) {
    final updatedPoints = currentPoints ?? this.currentPoints;
    final updatedLifetime = lifetimePoints ?? this.lifetimePoints;
    return LoyaltyAccount(
      userId: userId ?? this.userId,
      currentPoints: updatedPoints,
      lifetimePoints: updatedLifetime,
      tier: tier ?? LoyaltyTier.fromPoints(updatedLifetime),
      transactions: transactions ?? this.transactions,
    );
  }
}
