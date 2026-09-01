import 'dart:math';
import '../entities/gift_card_entity.dart';

/// Domain service for digital gift cards generation, validation, and redemption.
class GiftCardService {
  const GiftCardService();

  /// Generates a secure 16-character alphanumeric gift card voucher code formatted like `GIFT-XXXX-XXXX-XXXX`.
  String generateGiftCardCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    String block() => List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();
    return 'GIFT-${block()}-${block()}-${block()}';
  }

  /// Creates a newly purchased gift card.
  GiftCardEntity purchaseGiftCard({
    required double amount,
    required String senderName,
    required String recipientName,
    required String recipientPhone,
    String? personalMessage,
    GiftCardTheme theme = GiftCardTheme.gourmetGold,
    int validityDays = 365,
  }) {
    final now = DateTime.now();
    return GiftCardEntity(
      id: 'GC-${now.millisecondsSinceEpoch}',
      code: generateGiftCardCode(),
      initialAmount: amount,
      remainingBalance: amount,
      senderName: senderName,
      recipientName: recipientName,
      recipientPhone: recipientPhone,
      personalMessage: personalMessage,
      theme: theme,
      purchasedAt: now,
      expiresAt: now.add(Duration(days: validityDays)),
      isRedeemed: false,
    );
  }

  /// Redeems/deducts an amount from a gift card by matching code.
  GiftCardEntity redeemAmount({
    required GiftCardEntity card,
    required double amountToDeduct,
  }) {
    if (!card.isUsable) {
      throw StateError('بطاقة الهدية غير صالحة أو تم استخدام رصيدها بالكامل.');
    }

    final newBalance = (card.remainingBalance - amountToDeduct).clamp(0.0, double.infinity);
    final isFullyUsed = newBalance <= 0;

    return card.copyWith(
      remainingBalance: newBalance,
      isRedeemed: isFullyUsed,
      redeemedAt: isFullyUsed ? DateTime.now() : card.redeemedAt,
    );
  }
}
