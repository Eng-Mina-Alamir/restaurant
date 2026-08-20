import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/loyalty/domain/entities/loyalty_entity.dart';
import 'package:restaurant_app/features/loyalty/presentation/controllers/loyalty_controller.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('LoyaltyController Unit Tests', () {
    test('initializes and loads loyalty account and rewards', () async {
      final controller = container.read(loyaltyControllerProvider.notifier);
      await controller.loadAccount();

      final account = container.read(loyaltyControllerProvider);
      expect(account, isA<AsyncData<LoyaltyAccount>>());
      expect(account.value!.currentPoints, greaterThanOrEqualTo(0));

      final rewards = await container.read(availableRewardsProvider.future);
      expect(rewards.isNotEmpty, isTrue);
    });

    test('earnPoints increases points on loyalty account', () async {
      final controller = container.read(loyaltyControllerProvider.notifier);
      await controller.loadAccount();

      final initialPoints = container.read(loyaltyControllerProvider).value!.currentPoints;

      await controller.earnPoints(orderTotal: 100.0, orderId: 'ORD-TEST-1');
      final newPoints = container.read(loyaltyControllerProvider).value!.currentPoints;

      expect(newPoints, greaterThan(initialPoints));
    });

    test('redeemReward succeeds when points sufficient and fails when insufficient', () async {
      final controller = container.read(loyaltyControllerProvider.notifier);
      await controller.loadAccount();

      // Earn enough points first
      await controller.earnPoints(orderTotal: 1000.0, orderId: 'ORD-EARN-BIG');
      final currentPoints = container.read(loyaltyControllerProvider).value!.currentPoints;

      const cheapReward = LoyaltyReward(
        id: 'r-cheap',
        title: 'مشروب مجاني',
        description: 'وصف',
        pointsCost: 50,
        discountAmount: 10.0,
      );

      final success = await controller.redeemReward(cheapReward);
      expect(success, isTrue);
      expect(container.read(loyaltyControllerProvider).value!.currentPoints, currentPoints - 50);

      const expensiveReward = LoyaltyReward(
        id: 'r-huge',
        title: 'وجبة فاخرة',
        description: 'وصف',
        pointsCost: 999999,
        discountAmount: 500.0,
      );

      final failed = await controller.redeemReward(expensiveReward);
      expect(failed, isFalse);
    });
  });
}
