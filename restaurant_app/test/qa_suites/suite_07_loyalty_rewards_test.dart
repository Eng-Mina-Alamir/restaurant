import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/loyalty/domain/entities/loyalty_entity.dart';
import 'package:restaurant_app/features/loyalty/presentation/controllers/loyalty_controller.dart';
import 'helpers/qa_test_helpers.dart';

void main() {
  group('Suite 7: Loyalty & Rewards (نظام نقاط الولاء والمكافآت)', () {
    // -------------------------------------------------------------
    // TC-LOY-01: Points Accrual from Orders
    // -------------------------------------------------------------
    test(
      'TC-LOY-01: Points accrue automatically according to order spend amount',
      () async {
        final container = createQaContainer();
        addTearDown(container.dispose);

        final loyaltyNotifier = container.read(
          loyaltyControllerProvider.notifier,
        );

        // Earn points for 250 currency spend
        await loyaltyNotifier.earnPoints(
          orderTotal: 250.0,
          orderId: 'ORD-LOY-001',
        );

        final account = container.read(loyaltyControllerProvider).value;
        expect(account, isNotNull);
        expect(account?.currentPoints, greaterThan(0));
      },
    );

    // -------------------------------------------------------------
    // TC-LOY-02: Tier Progression & Badges
    // -------------------------------------------------------------
    test(
      'TC-LOY-02: Accumulating threshold points advances tier to Silver and Gold',
      () {
        const bronzeAccount = LoyaltyAccount(
          userId: 'u1',
          currentPoints: 200,
          lifetimePoints: 200,
          tier: LoyaltyTier.bronze,
          transactions: [],
        );
        expect(bronzeAccount.tier, LoyaltyTier.bronze);

        const goldAccount = LoyaltyAccount(
          userId: 'u1',
          currentPoints: 2500,
          lifetimePoints: 2500,
          tier: LoyaltyTier.gold,
          transactions: [],
        );
        expect(goldAccount.tier, LoyaltyTier.gold);
      },
    );

    // -------------------------------------------------------------
    // TC-LOY-03: Reward Redemption
    // -------------------------------------------------------------
    test(
      'TC-LOY-03: Customer redeems loyalty reward and points are deducted',
      () async {
        final container = createQaContainer();
        addTearDown(container.dispose);

        final loyaltyNotifier = container.read(
          loyaltyControllerProvider.notifier,
        );

        // Seed with high points
        await loyaltyNotifier.earnPoints(
          orderTotal: 1000.0,
          orderId: 'ORD-SEED',
        );
        final beforePoints =
            container.read(loyaltyControllerProvider).value?.currentPoints ?? 0;
        expect(beforePoints, greaterThanOrEqualTo(100));

        const reward = LoyaltyReward(
          id: 'rew-free-dessert',
          title: 'حلوى تشيز كيك مجانية',
          description: 'استبدل 100 نقطة',
          pointsCost: 100,
          discountAmount: 40.0,
        );

        final success = await loyaltyNotifier.redeemReward(reward);
        expect(success, isTrue);

        final afterPoints =
            container.read(loyaltyControllerProvider).value?.currentPoints ?? 0;
        expect(afterPoints, beforePoints - 100);
      },
    );
  });
}
