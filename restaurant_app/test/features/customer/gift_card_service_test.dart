import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/customer/domain/entities/gift_card_entity.dart';
import 'package:restaurant_app/features/customer/domain/services/gift_card_service.dart';

void main() {
  late GiftCardService service;

  setUp(() {
    service = const GiftCardService();
  });

  group('GiftCardService Tests', () {
    test('generateGiftCardCode returns formatted 16-character code', () {
      final code = service.generateGiftCardCode();
      expect(code.startsWith('GIFT-'), true);
      expect(code.split('-').length, 4);
    });

    test('purchaseGiftCard creates a valid usable gift card', () {
      final card = service.purchaseGiftCard(
        amount: 500.0,
        senderName: 'Mina',
        recipientName: 'Kyrolus',
        recipientPhone: '01000000000',
        personalMessage: 'Happy Birthday!',
        theme: GiftCardTheme.emeraldLuxury,
      );

      expect(card.initialAmount, 500.0);
      expect(card.remainingBalance, 500.0);
      expect(card.senderName, 'Mina');
      expect(card.recipientName, 'Kyrolus');
      expect(card.isUsable, true);
      expect(card.isRedeemed, false);
      expect(card.theme, GiftCardTheme.emeraldLuxury);
    });

    test('redeemAmount deducts balance and marks as redeemed when exhausted', () {
      final card = service.purchaseGiftCard(
        amount: 200.0,
        senderName: 'Mina',
        recipientName: 'Kyrolus',
        recipientPhone: '01000000000',
      );

      // Deduct 150
      final partial = service.redeemAmount(card: card, amountToDeduct: 150.0);
      expect(partial.remainingBalance, 50.0);
      expect(partial.isUsable, true);
      expect(partial.isRedeemed, false);

      // Deduct remaining 50
      final exhausted = service.redeemAmount(card: partial, amountToDeduct: 50.0);
      expect(exhausted.remainingBalance, 0.0);
      expect(exhausted.isUsable, false);
      expect(exhausted.isRedeemed, true);
      expect(exhausted.redeemedAt, isNotNull);

      // Attempting to redeem exhausted throws
      expect(
        () => service.redeemAmount(card: exhausted, amountToDeduct: 10.0),
        throwsStateError,
      );
    });
  });
}
