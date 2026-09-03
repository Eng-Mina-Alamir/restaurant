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

  final Map<String, LoyaltyAccount> _cachedAccounts = {};

  /// Drops cached ledgers. Called implicitly when the repository provider is
  /// invalidated on logout (see `AuthController.logout`); exposed for tests.
  void clearCache([String? userId]) {
    if (userId == null) {
      _cachedAccounts.clear();
    } else {
      _cachedAccounts.remove(userId);
    }
  }

  @override
  Future<Either<Failure, LoyaltyAccount>> getAccount(String userId) async {
    // Guest/demo identities (non-UUID) can never own a server ledger row —
    // answer locally instead of issuing a doomed query per screen open.
    if (!_isUuid(userId)) {
      return Right(
        LoyaltyAccount(
          userId: userId,
          currentPoints: 0,
          lifetimePoints: 0,
          tier: LoyaltyTier.fromPoints(0),
          transactions: const [],
        ),
      );
    }
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
      _cachedAccounts[userId] = account;
      return Right(account);
    } catch (e, st) {
      AppLogger.warning(
        'Supabase getAccount error: $e',
        error: e,
        stackTrace: st,
      );
      return Left(ServerFailure('فشل تحميل حساب الولاء من Supabase: $e'));
    }
  }

  @override
  Future<Either<Failure, LoyaltyAccount>> earnPoints({
    required String userId,
    required double orderTotal,
    required String orderId,
  }) async {
    try {
      await _supabase.rpc(
        'earn_loyalty_points',
        params: {'p_order_id': orderId},
      );
      return await getAccount(userId);
    } catch (e, st) {
      AppLogger.warning(
        'Supabase earnPoints error: $e',
        error: e,
        stackTrace: st,
      );
      return Left(ServerFailure('فشل احتساب نقاط الولاء: $e'));
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
      AppLogger.warning(
        'Supabase redeemReward error: $e',
        error: e,
        stackTrace: st,
      );
      return Left(ServerFailure('فشل استبدال مكافأة الولاء: $e'));
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
        rewards.add(
          LoyaltyReward(
            id: map['id']?.toString() ?? '',
            title: map['title'] as String? ?? '',
            description: map['description'] as String? ?? '',
            pointsCost: (map['points_cost'] as num?)?.toInt() ?? 0,
            discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0.0,
            minOrderAmount:
                (map['min_order_amount'] as num?)?.toDouble() ?? 0.0,
            iconName: map['icon_name'] as String? ?? 'card_giftcard',
          ),
        );
      }
      return Right(rewards);
    } catch (e, st) {
      AppLogger.warning(
        'Supabase getAvailableRewards error: $e',
        error: e,
        stackTrace: st,
      );
      return Left(ServerFailure('فشل تحميل مكافآت الولاء من Supabase: $e'));
    }
  }

  static bool _isUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);
  }
}
