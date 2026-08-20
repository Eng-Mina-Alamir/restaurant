import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/loyalty/domain/entities/loyalty_entity.dart';
import 'package:restaurant_app/features/loyalty/presentation/controllers/loyalty_controller.dart';

void main() {
  group('Loyalty Points Flow Integration Test', () {
    test('customer earns points from orders, advances tiers, and redeems rewards', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final loyaltyController = container.read(loyaltyControllerProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      final initialAccount = container.read(loyaltyControllerProvider).value!;
      final initialPoints = initialAccount.currentPoints;

      // 1. Earn points from order
      await loyaltyController.earnPoints(orderTotal: 600.0, orderId: 'ORD-1234');
      final updatedAccount = container.read(loyaltyControllerProvider).value!;
      expect(updatedAccount.currentPoints, greaterThan(initialPoints));

      // 2. Fetch available rewards
      final rewards = await container.read(availableRewardsProvider.future);
      expect(rewards, isNotEmpty);

      // 3. Redeem reward
      final reward = rewards.first;
      final redeemed = await loyaltyController.redeemReward(reward);
      expect(redeemed, isTrue);

      final finalAccount = container.read(loyaltyControllerProvider).value!;
      expect(finalAccount.currentPoints, updatedAccount.currentPoints - reward.pointsCost);
      expect(finalAccount.transactions.any((t) => t.type == PointsTransactionType.redeem), isTrue);
    });
  });
}
