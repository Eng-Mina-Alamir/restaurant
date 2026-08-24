import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/loyalty/data/repositories/in_memory_loyalty_repository.dart';
import 'package:restaurant_app/features/loyalty/domain/entities/loyalty_entity.dart';

void main() {
  group('Loyalty System Tests', () {
    late InMemoryLoyaltyRepository repository;

    setUp(() {
      repository = InMemoryLoyaltyRepository();
    });

    test('initializes customer with silver tier and welcome points', () async {
      final result = await repository.getAccount('cust-101');
      expect(result.isRight, isTrue);
      final account = result.when(onLeft: (_) => null, onRight: (a) => a);
      expect(account, isNotNull);
      expect(account!.tier, LoyaltyTier.silver);
      expect(account.currentPoints, 350);
      expect(account.transactions.isNotEmpty, isTrue);
    });

    test(
      'earns points from completed orders based on tier multiplier',
      () async {
        final result = await repository.earnPoints(
          userId: 'cust-101',
          orderTotal: 100.0,
          orderId: 'ORD-5555',
        );
        expect(result.isRight, isTrue);
        final account = result.when(onLeft: (_) => null, onRight: (a) => a);
        // 100 SAR * 1.25 (silver) = 125 points earned
        expect(account!.currentPoints, 350 + 125);
        expect(account.transactions.first.points, 125);
        expect(account.transactions.first.type, PointsTransactionType.earn);
      },
    );

    test('redeems reward when points balance is sufficient', () async {
      final rewardsResult = await repository.getAvailableRewards();
      final reward = rewardsResult
          .when(onLeft: (_) => null, onRight: (r) => r)!
          .first; // 100 points cost

      final result = await repository.redeemReward(
        userId: 'cust-101',
        reward: reward,
      );
      expect(result.isRight, isTrue);
      final account = result.when(onLeft: (_) => null, onRight: (a) => a);
      expect(account!.currentPoints, 350 - 100);
      expect(account.transactions.first.type, PointsTransactionType.redeem);
    });

    test('rejects redemption when points are insufficient', () async {
      const expensiveReward = LoyaltyReward(
        id: 'rew-max',
        title: 'مكافأة عملاقة',
        description: 'وصف',
        pointsCost: 10000,
        discountAmount: 1000,
      );

      final result = await repository.redeemReward(
        userId: 'cust-101',
        reward: expensiveReward,
      );
      expect(result.isLeft, isTrue);
    });

    test('tier progression calculates next tier thresholds', () {
      expect(LoyaltyTier.fromPoints(200), LoyaltyTier.bronze);
      expect(LoyaltyTier.fromPoints(600), LoyaltyTier.silver);
      expect(LoyaltyTier.fromPoints(1800), LoyaltyTier.gold);
      expect(LoyaltyTier.fromPoints(5000), LoyaltyTier.platinum);
    });
  });
}
