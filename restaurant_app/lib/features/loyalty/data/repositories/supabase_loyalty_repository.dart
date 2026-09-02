import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/supabase_config.dart';
import '../../../../core/data/local_cache_service.dart';
import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/loyalty_entity.dart';
import '../../domain/repositories/loyalty_repository.dart';

class SupabaseLoyaltyRepository implements LoyaltyRepository {
  SupabaseLoyaltyRepository({
    required SupabaseClient supabase,
    LocalCacheService? cache,
  })  : _supabase = supabase,
        _cache = cache;

  final SupabaseClient _supabase;
  final LocalCacheService? _cache;

  static const String _loyaltyCacheKeyPrefix = 'loyalty_account_';

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

  @override
  Future<Either<Failure, LoyaltyAccount>> getAccount(String userId) async {
    try {
      // 1. Fetch loyalty account
      final accountRaw = await _supabase
          .from(SupabaseConfig.loyaltyAccountsTable)
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      int currentPoints = 0;
      int lifetimePoints = 0;

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

        transactions.add(
          PointsTransaction(
            id: map['id']?.toString() ?? '',
            points: (map['points'] as num?)?.toInt() ?? 0,
            description: map['description'] as String? ?? '',
            createdAt: map['created_at'] != null
                ? DateTime.tryParse(map['created_at'] as String) ??
                      DateTime.now()
                : DateTime.now(),
            type: type,
          ),
        );
      }

      final account = LoyaltyAccount(
        userId: userId,
        currentPoints: currentPoints,
        lifetimePoints: lifetimePoints,
        tier: LoyaltyTier.fromPoints(lifetimePoints),
        transactions: transactions,
      );

      final cache = _cache;
      if (cache != null) {
        await cache.writeMap('$_loyaltyCacheKeyPrefix$userId', {
          'userId': account.userId,
          'currentPoints': account.currentPoints,
          'lifetimePoints': account.lifetimePoints,
          'tier': account.tier.name,
          'transactions': transactions.map((t) => {
            'id': t.id,
            'points': t.points,
            'description': t.description,
            'createdAt': t.createdAt.toIso8601String(),
            'type': t.type.name,
          }).toList(),
        });
      }

      return Right(account);
    } catch (e, st) {
      AppLogger.warning('Supabase getAccount fallback: $e', error: e, stackTrace: st);
      final cache = _cache;
      if (cache != null) {
        final cached = cache.readMap('$_loyaltyCacheKeyPrefix$userId');
        if (cached != null) {
          final rawTxs = cached['transactions'] as List? ?? [];
          final txs = rawTxs.whereType<Map>().map((m) {
            final map = Map<String, dynamic>.from(m);
            return PointsTransaction(
              id: map['id']?.toString() ?? '',
              points: (map['points'] as num?)?.toInt() ?? 0,
              description: map['description'] as String? ?? '',
              createdAt: map['createdAt'] != null
                  ? DateTime.parse(map['createdAt'] as String)
                  : DateTime.now(),
              type: PointsTransactionType.values.firstWhere(
                (t) => t.name == map['type'],
                orElse: () => PointsTransactionType.earn,
              ),
            );
          }).toList();

          return Right(
            LoyaltyAccount(
              userId: userId,
              currentPoints: (cached['currentPoints'] as num?)?.toInt() ?? 0,
              lifetimePoints: (cached['lifetimePoints'] as num?)?.toInt() ?? 0,
              tier: LoyaltyTier.values.firstWhere(
                (t) => t.name == cached['tier'],
                orElse: () => LoyaltyTier.bronze,
              ),
              transactions: txs,
            ),
          );
        }
      }

      final empty = LoyaltyAccount(
        userId: userId,
        currentPoints: 0,
        lifetimePoints: 0,
        tier: LoyaltyTier.bronze,
        transactions: const [],
      );
      return Right(empty);
    }
  }

  @override
  Future<Either<Failure, LoyaltyAccount>> earnPoints({
    required String userId,
    required double orderTotal,
    required String orderId,
  }) async {
    try {
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
      AppLogger.warning('Supabase earnPoints error: $e', error: e, stackTrace: st);
      return await getAccount(userId);
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
      AppLogger.warning('Supabase redeemReward error: $e', error: e, stackTrace: st);
      return await getAccount(userId);
    }
  }

  @override
  Future<Either<Failure, List<LoyaltyReward>>> getAvailableRewards() async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.loyaltyRewardsTable)
          .select()
          .order('points_cost', ascending: true);

      final List<LoyaltyReward> rewards = [];
      for (final raw in (response as List)) {
        final map = Map<String, dynamic>.from(raw as Map);
        rewards.add(
          LoyaltyReward(
            id: map['id']?.toString() ?? '',
            title: map['title'] as String? ?? '',
            description: map['description'] as String? ?? '',
            pointsCost: (map['points_cost'] as num?)?.toInt() ?? 0,
            discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0.0,
            minOrderAmount: (map['min_order_amount'] as num?)?.toDouble() ?? 0.0,
            iconName: map['icon_name'] as String? ?? 'stars',
          ),
        );
      }

      if (rewards.isEmpty) {
        return Right(_defaultRewards);
      }
      return Right(rewards);
    } catch (e, st) {
      AppLogger.warning('Supabase getAvailableRewards fallback: $e', error: e, stackTrace: st);
      return Right(_defaultRewards);
    }
  }
}
