import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../config/app_config.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/gift_card_entity.dart';
import '../../domain/services/gift_card_service.dart';

final giftCardServiceProvider = Provider<GiftCardService>((ref) {
  return const GiftCardService();
});

/// Controller managing customer's digital gift cards and voucher wallet.
class GiftCardController extends StateNotifier<List<GiftCardEntity>> {
  GiftCardController(this._service, {SupabaseClient? supabase})
      : _supabase = supabase,
        super(_seedInitialCards()) {
    if (_supabase != null) {
      _loadFromSupabase();
    }
  }

  final GiftCardService _service;
  final SupabaseClient? _supabase;

  Future<void> _loadFromSupabase() async {
    final client = _supabase;
    if (client == null) return;
    try {
      final rows = await client
          .from('gift_cards')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      if (rows.isNotEmpty) {
        final List<GiftCardEntity> cards = [];
        for (final r in (rows as List)) {
          final m = Map<String, dynamic>.from(r as Map);
          cards.add(
            GiftCardEntity(
              id: m['id']?.toString() ?? '',
              code: m['code']?.toString() ?? '',
              initialAmount: (m['initial_balance'] as num?)?.toDouble() ?? 0.0,
              remainingBalance: (m['current_balance'] as num?)?.toDouble() ?? 0.0,
              senderName: 'مطعم ليالي المحروسة',
              recipientName: 'عميل المحروسة',
              recipientPhone: '01012345678',
              personalMessage: 'كارت هدية صالح لجميع أطباق ومشاوي المحروسة 🍔🎉',
              theme: GiftCardTheme.gourmetGold,
              purchasedAt: DateTime.tryParse(m['created_at']?.toString() ?? '') ?? DateTime.now(),
              expiresAt: DateTime.tryParse(m['expires_at']?.toString() ?? '') ??
                  DateTime.now().add(const Duration(days: 365)),
            ),
          );
        }
        state = cards;
      }
    } catch (e) {
      AppLogger.warning('GiftCardController loadFromSupabase error: $e');
    }
  }

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

    final client = _supabase;
    if (client != null) {
      Future.microtask(() async {
        try {
          await client.from('gift_cards').insert({
            'id': card.id,
            'code': card.code,
            'initial_balance': card.initialAmount,
            'current_balance': card.remainingBalance,
            'is_active': true,
            'expires_at': card.expiresAt?.toIso8601String(),
            'created_at': card.purchasedAt.toIso8601String(),
          });
        } catch (e) {
          AppLogger.warning('GiftCard purchaseCard sync error: $e');
        }
      });
    }

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

    final client = _supabase;
    if (client != null) {
      Future.microtask(() async {
        try {
          await client.from('gift_cards').update({
            'current_balance': updated.remainingBalance,
            'is_active': updated.remainingBalance > 0,
          }).eq('code', cleanCode);
        } catch (e) {
          AppLogger.warning('GiftCard redeemCode sync error: $e');
        }
      });
    }

    return deduct;
  }
}

final giftCardControllerProvider =
    StateNotifierProvider<GiftCardController, List<GiftCardEntity>>((ref) {
  final service = ref.watch(giftCardServiceProvider);
  final supabase = AppConfig.useSupabase ? ref.watch(supabaseClientProvider) : null;
  return GiftCardController(service, supabase: supabase);
});
