import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/errors/either.dart';
import 'package:restaurant_app/core/errors/failures.dart';
import 'package:restaurant_app/features/loyalty/data/repositories/in_memory_loyalty_repository.dart';
import 'package:restaurant_app/features/loyalty/domain/entities/loyalty_entity.dart';

void main() {
  group('Loyalty Repository & Entity Unit Tests', () {
    late InMemoryLoyaltyRepository repository;

    setUp(() {
      repository = InMemoryLoyaltyRepository();
    });

    test(
      'getAccount creates or returns user account with initial balance',
      () async {
        final result = await repository.getAccount('usr-loyalty-1');
        expect(result.isRight, isTrue);
        final account = (result as Right<Failure, LoyaltyAccount>).value;
        expect(account.currentPoints, 350);
        expect(account.tier, LoyaltyTier.silver);
      },
    );

    test('earnPoints adds points multiplied by tier multiplier', () async {
      final earnResult = await repository.earnPoints(
        userId: 'usr-loyalty-1',
        orderTotal: 100.0,
        orderId: 'ORD-555',
      );

      expect(earnResult.isRight, isTrue);
      final account = (earnResult as Right<Failure, LoyaltyAccount>).value;
      expect(account.currentPoints, 475);
      expect(account.transactions.first.type, PointsTransactionType.earn);
    });

    test('redeemReward deducts points when balance is sufficient', () async {
      const reward = LoyaltyReward(
        id: 'rew-10',
        title: 'خصم 10',
        description: 'خصم فوري',
        pointsCost: 100,
        discountAmount: 10.0,
      );

      final redeemResult = await repository.redeemReward(
        userId: 'usr-loyalty-1',
        reward: reward,
      );

      expect(redeemResult.isRight, isTrue);
      final account = (redeemResult as Right<Failure, LoyaltyAccount>).value;
      expect(account.currentPoints, 250); // 350 - 100
      expect(account.transactions.first.points, -100);
    });

    test('redeemReward rejects when points are insufficient', () async {
      const expensiveReward = LoyaltyReward(
        id: 'rew-1000',
        title: 'عشاء مجاني سنوي',
        description: 'مكافأة باهظة',
        pointsCost: 9000,
        discountAmount: 1000.0,
      );

      final result = await repository.redeemReward(
        userId: 'usr-loyalty-1',
        reward: expensiveReward,
      );

      expect(result.isLeft, isTrue);
    });

    test('getAvailableRewards returns predefined rewards catalogue', () async {
      final rewardsResult = await repository.getAvailableRewards();
      expect(rewardsResult.isRight, isTrue);
      expect(
        (rewardsResult as Right<Failure, List<LoyaltyReward>>).value.length,
        4,
      );
    });
  });
}
