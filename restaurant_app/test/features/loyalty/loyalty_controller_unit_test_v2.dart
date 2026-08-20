import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/errors/either.dart';
import 'package:restaurant_app/core/errors/failures.dart';
import 'package:restaurant_app/features/loyalty/domain/entities/loyalty_entity.dart';
import 'package:restaurant_app/features/loyalty/domain/repositories/loyalty_repository.dart';
import 'package:restaurant_app/features/loyalty/presentation/controllers/loyalty_controller.dart';

class _FakeLoyaltyRepository implements LoyaltyRepository {
  LoyaltyAccount? account;
  bool shouldFailRedeem = false;

  @override
  Future<Either<Failure, LoyaltyAccount>> getAccount(String userId) async {
    account ??= LoyaltyAccount(
      userId: userId,
      currentPoints: 600,
      lifetimePoints: 600,
      tier: LoyaltyTier.silver,
      transactions: const [],
    );
    return Right(account!);
  }

  @override
  Future<Either<Failure, List<LoyaltyReward>>> getAvailableRewards() async {
    return const Right([
      LoyaltyReward(
        id: 'rew-1',
        title: 'خصم 20 جنيه',
        description: 'خصم مباشر',
        pointsCost: 200,
        discountAmount: 20.0,
      ),
    ]);
  }

  @override
  Future<Either<Failure, LoyaltyAccount>> redeemReward({
    required String userId,
    required LoyaltyReward reward,
  }) async {
    if (shouldFailRedeem || (account?.currentPoints ?? 0) < reward.pointsCost) {
      return const Left(ValidationFailure('نقاطك لا تكفي لاستبدال هذه المكافأة'));
    }

    account = account!.copyWith(
      currentPoints: account!.currentPoints - reward.pointsCost,
      transactions: [
        ...account!.transactions,
        PointsTransaction(
          id: 'tx-red',
          points: -reward.pointsCost,
          description: 'استبدال ${reward.title}',
          createdAt: DateTime.now(),
          type: PointsTransactionType.redeem,
        ),
      ],
    );
    return Right(account!);
  }

  @override
  Future<Either<Failure, LoyaltyAccount>> earnPoints({
    required String userId,
    required double orderTotal,
    required String orderId,
  }) async {
    final earned = (orderTotal * 1.0).round();
    account = account!.copyWith(
      currentPoints: account!.currentPoints + earned,
      lifetimePoints: account!.lifetimePoints + earned,
    );
    return Right(account!);
  }
}

void main() {
  group('LoyaltyController and Tier Calculation Tests (v2)', () {
    test('LoyaltyTier.fromPoints calculates correct tiers', () {
      expect(LoyaltyTier.fromPoints(0), LoyaltyTier.bronze);
      expect(LoyaltyTier.fromPoints(499), LoyaltyTier.bronze);
      expect(LoyaltyTier.fromPoints(500), LoyaltyTier.silver);
      expect(LoyaltyTier.fromPoints(1499), LoyaltyTier.silver);
      expect(LoyaltyTier.fromPoints(1500), LoyaltyTier.gold);
      expect(LoyaltyTier.fromPoints(3000), LoyaltyTier.platinum);
      expect(LoyaltyTier.fromPoints(5000), LoyaltyTier.platinum);
    });

    test('LoyaltyTier nextTier property progression', () {
      expect(LoyaltyTier.bronze.nextTier, LoyaltyTier.silver);
      expect(LoyaltyTier.silver.nextTier, LoyaltyTier.gold);
      expect(LoyaltyTier.gold.nextTier, LoyaltyTier.platinum);
      expect(LoyaltyTier.platinum.nextTier, isNull);
    });

    test('LoyaltyController loads account on initialization', () async {
      final repo = _FakeLoyaltyRepository();
      final controller = LoyaltyController(repository: repo, userId: 'usr-1');

      await Future<void>.delayed(Duration.zero);
      expect(controller.state.hasValue, isTrue);
      expect(controller.state.value?.currentPoints, 600);
      expect(controller.state.value?.tier, LoyaltyTier.silver);
    });

    test('redeemReward deducts points and returns true on success', () async {
      final repo = _FakeLoyaltyRepository();
      final controller = LoyaltyController(repository: repo, userId: 'usr-1');
      await Future<void>.delayed(Duration.zero);

      const reward = LoyaltyReward(
        id: 'rew-1',
        title: 'خصم 20',
        description: '',
        pointsCost: 200,
        discountAmount: 20.0,
      );

      final success = await controller.redeemReward(reward);
      expect(success, isTrue);
      expect(controller.state.value?.currentPoints, 400);
    });

    test('redeemReward returns false on failure', () async {
      final repo = _FakeLoyaltyRepository();
      repo.shouldFailRedeem = true;
      final controller = LoyaltyController(repository: repo, userId: 'usr-1');
      await Future<void>.delayed(Duration.zero);

      const reward = LoyaltyReward(
        id: 'rew-1',
        title: 'خصم 20',
        description: '',
        pointsCost: 200,
        discountAmount: 20.0,
      );

      final success = await controller.redeemReward(reward);
      expect(success, isFalse);
    });

    test('earnPoints increases balance based on order total', () async {
      final repo = _FakeLoyaltyRepository();
      final controller = LoyaltyController(repository: repo, userId: 'usr-1');
      await Future<void>.delayed(Duration.zero);

      await controller.earnPoints(orderTotal: 100.0, orderId: 'ORD-1');
      expect(controller.state.value?.currentPoints, 700);
      expect(controller.state.value?.lifetimePoints, 700);
    });
  });
}
