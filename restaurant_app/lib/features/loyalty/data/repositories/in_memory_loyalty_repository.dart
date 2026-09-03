import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/loyalty_entity.dart';
import '../../domain/repositories/loyalty_repository.dart';

class InMemoryLoyaltyRepository implements LoyaltyRepository {
  final Map<String, LoyaltyAccount> _accounts = {};

  static final List<LoyaltyReward> _defaultRewards = [
    const LoyaltyReward(
      id: 'rew-10',
      title: 'خصم 10 ج.م فوري',
      description: 'خصم مباشر 10 ج.م على أي طلب بقيمة 50 ج.م أو أكثر',
      pointsCost: 100,
      discountAmount: 10.0,
      minOrderAmount: 50.0,
      iconName: 'local_offer',
    ),
    const LoyaltyReward(
      id: 'rew-25',
      title: 'خصم 25 ج.م VIP',
      description: 'خصم 25 ج.م على طلبات العشاء والولائم فوق 100 ج.م',
      pointsCost: 220,
      discountAmount: 25.0,
      minOrderAmount: 100.0,
      iconName: 'stars',
    ),
    const LoyaltyReward(
      id: 'rew-50',
      title: 'وجبة مجانية / خصم 50 ج.م',
      description:
          'قسيمة خصم بقيمة 50 ج.م صالحة على جميع الأصناف بدون حد أدنى',
      pointsCost: 400,
      discountAmount: 50.0,
      minOrderAmount: 0.0,
      iconName: 'restaurant',
    ),
    const LoyaltyReward(
      id: 'rew-100',
      title: 'قسيمة النخبة 100 ج.م',
      description:
          'أعلى مكافأة ولاء - خصم 100 ج.م فوري لأعضاء الفئات الذهبية والبلاتينية',
      pointsCost: 750,
      discountAmount: 100.0,
      minOrderAmount: 0.0,
      iconName: 'workspace_premium',
    ),
  ];

  LoyaltyAccount _getOrCreate(String userId) {
    if (!_accounts.containsKey(userId)) {
      final now = DateTime.now();
      _accounts[userId] = LoyaltyAccount(
        userId: userId,
        currentPoints: 350,
        lifetimePoints: 850,
        tier: LoyaltyTier.silver,
        transactions: [
          PointsTransaction(
            id: 'tx-1',
            points: 100,
            description: 'هدية الانضمام لبرنامج الولاء',
            createdAt: now.subtract(const Duration(days: 30)),
            type: PointsTransactionType.bonus,
          ),
          PointsTransaction(
            id: 'tx-2',
            points: 150,
            description: 'نقاط طلب #ORD-1012',
            createdAt: now.subtract(const Duration(days: 14)),
            type: PointsTransactionType.earn,
          ),
          PointsTransaction(
            id: 'tx-3',
            points: 100,
            description: 'نقاط طلب #ORD-1035',
            createdAt: now.subtract(const Duration(days: 3)),
            type: PointsTransactionType.earn,
          ),
        ],
      );
    }
    return _accounts[userId]!;
  }

  @override
  Future<Either<Failure, LoyaltyAccount>> getAccount(String userId) async {
    return right(_getOrCreate(userId));
  }

  @override
  Future<Either<Failure, LoyaltyAccount>> earnPoints({
    required String userId,
    required double orderTotal,
    required String orderId,
  }) async {
    final account = _getOrCreate(userId);
    // Base rule: 1 point per 1 SAR * tier multiplier
    final earned = (orderTotal * account.tier.multiplier).round();
    if (earned <= 0) return right(account);

    final tx = PointsTransaction(
      id: 'tx-${DateTime.now().millisecondsSinceEpoch}',
      points: earned,
      description: 'نقاط الطلب #$orderId',
      createdAt: DateTime.now(),
      type: PointsTransactionType.earn,
    );

    final updated = account.copyWith(
      currentPoints: account.currentPoints + earned,
      lifetimePoints: account.lifetimePoints + earned,
      transactions: [tx, ...account.transactions],
    );

    _accounts[userId] = updated;
    return right(updated);
  }

  @override
  Future<Either<Failure, LoyaltyAccount>> redeemReward({
    required String userId,
    required LoyaltyReward reward,
  }) async {
    final account = _getOrCreate(userId);
    if (account.currentPoints < reward.pointsCost) {
      return left(
        const Failure.validation('رصيد نقاطك غير كافٍ لاستبدال هذه المكافأة'),
      );
    }

    final tx = PointsTransaction(
      id: 'tx-${DateTime.now().millisecondsSinceEpoch}',
      points: -reward.pointsCost,
      description: 'استبدال مكافأة: ${reward.title}',
      createdAt: DateTime.now(),
      type: PointsTransactionType.redeem,
    );

    final updated = account.copyWith(
      currentPoints: account.currentPoints - reward.pointsCost,
      transactions: [tx, ...account.transactions],
    );

    _accounts[userId] = updated;
    return right(updated);
  }

  @override
  Future<Either<Failure, List<LoyaltyReward>>> getAvailableRewards() async {
    return right(_defaultRewards);
  }
}
