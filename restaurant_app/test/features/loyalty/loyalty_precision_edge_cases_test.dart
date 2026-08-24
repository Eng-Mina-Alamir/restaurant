import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/loyalty/data/repositories/in_memory_loyalty_repository.dart';
import 'package:restaurant_app/features/loyalty/domain/entities/loyalty_entity.dart';

void main() {
  group('Loyalty Tier & Calculation Precision Tests', () {
    test(
      'LoyaltyTier.fromPoints correctly assigns tiers at exact threshold boundaries',
      () {
        // Bronze: 0 .. 499
        expect(LoyaltyTier.fromPoints(0), LoyaltyTier.bronze);
        expect(LoyaltyTier.fromPoints(499), LoyaltyTier.bronze);

        // Silver: 500 .. 1499
        expect(LoyaltyTier.fromPoints(500), LoyaltyTier.silver);
        expect(LoyaltyTier.fromPoints(1499), LoyaltyTier.silver);

        // Gold: 1500 .. 2999
        expect(LoyaltyTier.fromPoints(1500), LoyaltyTier.gold);
        expect(LoyaltyTier.fromPoints(2999), LoyaltyTier.gold);

        // Platinum: 3000+
        expect(LoyaltyTier.fromPoints(3000), LoyaltyTier.platinum);
        expect(LoyaltyTier.fromPoints(10000), LoyaltyTier.platinum);

        // Negative values safely map to Bronze
        expect(LoyaltyTier.fromPoints(-50), LoyaltyTier.bronze);
      },
    );

    test('nextTier correctly resolves progressive progression', () {
      expect(LoyaltyTier.bronze.nextTier, LoyaltyTier.silver);
      expect(LoyaltyTier.silver.nextTier, LoyaltyTier.gold);
      expect(LoyaltyTier.gold.nextTier, LoyaltyTier.platinum);
      expect(LoyaltyTier.platinum.nextTier, isNull);
    });

    test(
      'Earning points applies tier multiplier and updates current & lifetime points',
      () async {
        final repo = InMemoryLoyaltyRepository();
        const testUser = 'user-edge-test-1';

        // Seed account with 0 points
        await repo.getAccount(testUser);

        // Order total 100 SAR on Silver tier (1.25 multiplier) -> 125 points
        final result = await repo.earnPoints(
          userId: testUser,
          orderTotal: 100.0,
          orderId: 'ORD-1001',
        );

        expect(result.isRight, isTrue);
        result.when(
          onLeft: (_) => fail('Should succeed'),
          onRight: (account) {
            // Initial seed was 350 current + 125 = 475
            expect(account.currentPoints, 475);
            // Lifetime was 850 + 125 = 975
            expect(account.lifetimePoints, 975);
          },
        );
      },
    );

    test('Zero or negative order totals do not generate points', () async {
      final repo = InMemoryLoyaltyRepository();
      const testUser = 'user-edge-test-2';

      final initial = await repo.getAccount(testUser);
      final initialPoints = initial.when(
        onLeft: (_) => 0,
        onRight: (a) => a.currentPoints,
      );

      final zeroResult = await repo.earnPoints(
        userId: testUser,
        orderTotal: 0.0,
        orderId: 'ORD-ZERO',
      );
      final zeroPoints = zeroResult.when(
        onLeft: (_) => -1,
        onRight: (a) => a.currentPoints,
      );
      expect(zeroPoints, initialPoints);

      final negResult = await repo.earnPoints(
        userId: testUser,
        orderTotal: -50.0,
        orderId: 'ORD-NEG',
      );
      final negPoints = negResult.when(
        onLeft: (_) => -1,
        onRight: (a) => a.currentPoints,
      );
      expect(negPoints, initialPoints);
    });

    test(
      'Redeeming rewards fails with Failure if insufficient points',
      () async {
        final repo = InMemoryLoyaltyRepository();
        const testUser = 'user-edge-test-3';

        const expensiveReward = LoyaltyReward(
          id: 'rew-huge',
          title: 'مكافأة عملاقة',
          description: 'تتطلب 5000 نقطة',
          pointsCost: 5000,
          discountAmount: 500.0,
        );

        final result = await repo.redeemReward(
          userId: testUser,
          reward: expensiveReward,
        );

        expect(result.isLeft, isTrue);
        result.when(
          onLeft: (failure) {
            expect(failure.message, contains('غير كاف'));
          },
          onRight: (_) =>
              fail('Should not allow redeeming with insufficient points'),
        );
      },
    );

    test(
      'Redeeming reward deducts points from currentPoints but preserves lifetimePoints',
      () async {
        final repo = InMemoryLoyaltyRepository();
        const testUser = 'user-edge-test-4';

        final initialAccountResult = await repo.getAccount(testUser);
        int startCurrent = 0;
        int startLifetime = 0;
        initialAccountResult.when(
          onLeft: (_) => fail('Should load initial'),
          onRight: (a) {
            startCurrent = a.currentPoints; // 350
            startLifetime = a.lifetimePoints; // 850
          },
        );

        const reward = LoyaltyReward(
          id: 'rew-10',
          title: 'خصم 10 ريال',
          description: '100 نقطة',
          pointsCost: 100,
          discountAmount: 10.0,
        );

        final result = await repo.redeemReward(
          userId: testUser,
          reward: reward,
        );

        expect(result.isRight, isTrue);
        result.when(
          onLeft: (_) => fail('Should succeed'),
          onRight: (updated) {
            expect(updated.currentPoints, startCurrent - 100);
            expect(
              updated.lifetimePoints,
              startLifetime,
            ); // Lifetime points must NOT decrease!
          },
        );
      },
    );
  });
}
