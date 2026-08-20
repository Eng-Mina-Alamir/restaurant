import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/supabase_config.dart';
import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/loyalty_entity.dart';
import '../../domain/repositories/loyalty_repository.dart';

class SupabaseLoyaltyRepository implements LoyaltyRepository {
  SupabaseLoyaltyRepository({required SupabaseClient supabase})
      : _supabase = supabase;

  final SupabaseClient _supabase;

  static final List<LoyaltyReward> _defaultRewards = [
    const LoyaltyReward(
      id: 'rew-01',
      title: 'مشروب غازي مجاني',
      description: 'اختر أي مشروب غازي مع وجبتك',
      pointsCost: 50,
      discountAmount: 10.0,
      iconName: 'local_drink',
    ),
    const LoyaltyReward(
      id: 'rew-02',
      title: 'خصم 25 ج.م على طلبك',
      description: 'خصم مباشر عند الوصول لـ 100 نقطة',
      pointsCost: 100,
      discountAmount: 25.0,
      minOrderAmount: 100.0,
      iconName: 'local_offer',
    ),
    const LoyaltyReward(
      id: 'rew-03',
      title: 'طبق حلى مجاني',
      description: 'أم علي بالمكسرات أو طبق أرز باللبن',
      pointsCost: 200,
      discountAmount: 35.0,
      iconName: 'cake',
    ),
    const LoyaltyReward(
      id: 'rew-04',
      title: 'خصم 75 ج.م على المشاوي',
      description: 'خصم خاص لكبار العملاء',
      pointsCost: 350,
      discountAmount: 75.0,
      minOrderAmount: 200.0,
      iconName: 'stars',
    ),
  ];

  final Map<String, LoyaltyAccount> _cachedAccounts = {};

  @override
  Future<Either<Failure, LoyaltyAccount>> getAccount(String userId) async {
    try {
      // 1. Fetch loyalty account
      final accountRaw = await _supabase
          .from(SupabaseConfig.loyaltyAccountsTable)
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      int currentPoints = 150;
      int lifetimePoints = 150;

      if (accountRaw != null) {
        currentPoints = (accountRaw['current_points'] as num?)?.toInt() ?? 0;
        lifetimePoints = (accountRaw['lifetime_points'] as num?)?.toInt() ?? 0;
      }

      // 2. Fetch transactions
      final txResponse = await _supabase
          .from(SupabaseConfig.loyaltyTransactionsTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final List<PointsTransaction> transactions = [];
      for (final raw in (txResponse as List)) {
        final map = Map<String, dynamic>.from(raw as Map);
        final typeStr = map['type'] as String? ?? 'earn';
        final type = PointsTransactionType.values.firstWhere(
          (t) => t.name == typeStr,
          orElse: () => PointsTransactionType.earn,
        );

        transactions.add(PointsTransaction(
          id: map['id']?.toString() ?? '',
          points: (map['points'] as num?)?.toInt() ?? 0,
          description: map['description'] as String? ?? '',
          createdAt: map['created_at'] != null
              ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
              : DateTime.now(),
          type: type,
        ));
      }

      final account = LoyaltyAccount(
        userId: userId,
        currentPoints: currentPoints,
        lifetimePoints: lifetimePoints,
        tier: LoyaltyTier.fromPoints(lifetimePoints),
        transactions: transactions,
      );
      _cachedAccounts[userId] = account;
      return Right(account);
    } catch (e, st) {
      AppLogger.warning('Supabase getAccount fallback: $e', error: e, stackTrace: st);
      final account = _cachedAccounts[userId] ??
          LoyaltyAccount(
            userId: userId,
            currentPoints: 150,
            lifetimePoints: 150,
            tier: LoyaltyTier.silver,
            transactions: const [],
          );
      return Right(account);
    }
  }

  @override
  Future<Either<Failure, LoyaltyAccount>> earnPoints({
    required String userId,
    required double orderTotal,
    required String orderId,
  }) async {
    try {
      // Call secure server RPC
      try {
        await _supabase.rpc(
          'earn_loyalty_points',
          params: {'p_order_id': orderId},
        );
      } catch (rpcError) {
        AppLogger.warning('earn_loyalty_points RPC error: $rpcError');
      }

      return await getAccount(userId);
    } catch (e, st) {
      AppLogger.warning('Supabase earnPoints fallback: $e', error: e, stackTrace: st);
      final prev = _cachedAccounts[userId] ??
          LoyaltyAccount(
            userId: userId,
            currentPoints: 150,
            lifetimePoints: 150,
            tier: LoyaltyTier.silver,
            transactions: const [],
          );
      final earned = (orderTotal / 10).floor();
      final updated = prev.copyWith(
        currentPoints: prev.currentPoints + earned,
        lifetimePoints: prev.lifetimePoints + earned,
      );
      _cachedAccounts[userId] = updated;
      return Right(updated);
    }
  }

  @override
  Future<Either<Failure, LoyaltyAccount>> redeemReward({
    required String userId,
    required LoyaltyReward reward,
  }) async {
    try {
      await _supabase.rpc(
        'redeem_loyalty_reward',
        params: {'p_reward_id': reward.id},
      );

      return await getAccount(userId);
    } catch (e, st) {
      AppLogger.warning('Supabase redeemReward fallback: $e', error: e, stackTrace: st);
      final prev = _cachedAccounts[userId] ??
          LoyaltyAccount(
            userId: userId,
            currentPoints: 150,
            lifetimePoints: 150,
            tier: LoyaltyTier.silver,
            transactions: const [],
          );
      final updated = prev.copyWith(
        currentPoints: (prev.currentPoints - reward.pointsCost).clamp(0, 999999),
      );
      _cachedAccounts[userId] = updated;
      return Right(updated);
    }
  }

  @override
  Future<Either<Failure, List<LoyaltyReward>>> getAvailableRewards() async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.loyaltyRewardsTable)
          .select()
          .eq('is_active', true)
          .order('points_cost', ascending: true);

      final List<LoyaltyReward> rewards = [];
      for (final raw in (response as List)) {
        final map = Map<String, dynamic>.from(raw as Map);
        rewards.add(LoyaltyReward(
          id: map['id']?.toString() ?? '',
          title: map['title'] as String? ?? '',
          description: map['description'] as String? ?? '',
          pointsCost: (map['points_cost'] as num?)?.toInt() ?? 0,
          discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0.0,
          minOrderAmount: (map['min_order_amount'] as num?)?.toDouble() ?? 0.0,
          iconName: map['icon_name'] as String? ?? 'card_giftcard',
        ));
      }
      if (rewards.isEmpty) return Right(_defaultRewards);
      return Right(rewards);
    } catch (e, st) {
      AppLogger.warning('Supabase getAvailableRewards fallback: $e', error: e, stackTrace: st);
      return Right(_defaultRewards);
    }
  }
}
