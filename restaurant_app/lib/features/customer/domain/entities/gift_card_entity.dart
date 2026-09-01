import 'package:flutter/foundation.dart';

/// Graphic theme styling for digital gift cards.
enum GiftCardTheme {
  gourmetGold,
  birthdayParty,
  celebrationRed,
  emeraldLuxury;

  String get labelAr {
    switch (this) {
      case GiftCardTheme.gourmetGold:
        return 'ذواقة ذهبي فاخر';
      case GiftCardTheme.birthdayParty:
        return 'عيد ميلاد واحتفال';
      case GiftCardTheme.celebrationRed:
        return 'تهنئة وسعادة';
      case GiftCardTheme.emeraldLuxury:
        return 'زمردي راقي';
    }
  }
}

/// Digital Gift Card representation.
@immutable
class GiftCardEntity {
  const GiftCardEntity({
    required this.id,
    required this.code,
    required this.initialAmount,
    required this.remainingBalance,
    required this.senderName,
    required this.recipientName,
    required this.recipientPhone,
    this.personalMessage,
    this.theme = GiftCardTheme.gourmetGold,
    required this.purchasedAt,
    this.expiresAt,
    this.isRedeemed = false,
    this.redeemedAt,
  });

  final String id;
  final String code;
  final double initialAmount;
  final double remainingBalance;
  final String senderName;
  final String recipientName;
  final String recipientPhone;
  final String? personalMessage;
  final GiftCardTheme theme;
  final DateTime purchasedAt;
  final DateTime? expiresAt;
  final bool isRedeemed;
  final DateTime? redeemedAt;

  bool get isUsable => remainingBalance > 0 && !isRedeemed;

  GiftCardEntity copyWith({
    String? id,
    String? code,
    double? initialAmount,
    double? remainingBalance,
    String? senderName,
    String? recipientName,
    String? recipientPhone,
    String? personalMessage,
    GiftCardTheme? theme,
    DateTime? purchasedAt,
    DateTime? expiresAt,
    bool? isRedeemed,
    DateTime? redeemedAt,
  }) {
    return GiftCardEntity(
      id: id ?? this.id,
      code: code ?? this.code,
      initialAmount: initialAmount ?? this.initialAmount,
      remainingBalance: remainingBalance ?? this.remainingBalance,
      senderName: senderName ?? this.senderName,
      recipientName: recipientName ?? this.recipientName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      personalMessage: personalMessage ?? this.personalMessage,
      theme: theme ?? this.theme,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isRedeemed: isRedeemed ?? this.isRedeemed,
      redeemedAt: redeemedAt ?? this.redeemedAt,
    );
  }
}
