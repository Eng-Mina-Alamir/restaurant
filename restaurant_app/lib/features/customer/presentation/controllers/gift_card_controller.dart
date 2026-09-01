import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/gift_card_entity.dart';
import '../../domain/services/gift_card_service.dart';

final giftCardServiceProvider = Provider<GiftCardService>((ref) {
  return const GiftCardService();
});

/// Controller managing customer's digital gift cards and voucher wallet.
class GiftCardController extends StateNotifier<List<GiftCardEntity>> {
  GiftCardController(this._service) : super(_seedInitialCards());

  final GiftCardService _service;

  static List<GiftCardEntity> _seedInitialCards() {
    final now = DateTime.now();
    return [
      GiftCardEntity(
        id: 'GC-101',
        code: 'GIFT-GOLD-8821-VVIP',
        initialAmount: 250.0,
        remainingBalance: 250.0,
        senderName: 'سارة أحمد',
        recipientName: 'كيرلس سمير',
        recipientPhone: '01000000001',
        personalMessage: 'ألف مبروك الترقية يا صديقي! استمتع بأشهى وجبة 🍔🎉',
        theme: GiftCardTheme.gourmetGold,
        purchasedAt: now.subtract(const Duration(days: 2)),
        expiresAt: now.add(const Duration(days: 363)),
      ),
    ];
  }

  /// Purchases a new digital gift card and adds it to wallet.
  GiftCardEntity purchaseCard({
    required double amount,
    required String senderName,
    required String recipientName,
    required String recipientPhone,
    String? personalMessage,
    GiftCardTheme theme = GiftCardTheme.gourmetGold,
  }) {
    final card = _service.purchaseGiftCard(
      amount: amount,
      senderName: senderName,
      recipientName: recipientName,
      recipientPhone: recipientPhone,
      personalMessage: personalMessage,
      theme: theme,
    );
    state = [card, ...state];
    return card;
  }

  /// Redeems an amount from a gift card by its code. Returns the redeemed amount or null if failed.
  double? redeemCode({
    required String code,
    double? amountToDeduct,
  }) {
    final cleanCode = code.trim().toUpperCase();
    final index = state.indexWhere((c) => c.code.toUpperCase() == cleanCode);
    if (index == -1) return null;

    final target = state[index];
    if (!target.isUsable || target.remainingBalance <= 0) return null;

    final deduct = (amountToDeduct != null && amountToDeduct > 0)
        ? amountToDeduct
        : target.remainingBalance;

    final updated = _service.redeemAmount(
      card: target,
      amountToDeduct: deduct,
    );

    final updatedList = List<GiftCardEntity>.from(state);
    updatedList[index] = updated;
    state = updatedList;
    return deduct;
  }
}

final giftCardControllerProvider =
    StateNotifierProvider<GiftCardController, List<GiftCardEntity>>((ref) {
  final service = ref.watch(giftCardServiceProvider);
  return GiftCardController(service);
});
