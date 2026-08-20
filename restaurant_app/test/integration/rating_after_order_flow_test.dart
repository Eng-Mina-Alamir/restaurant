import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/ratings/domain/entities/rating_entity.dart';
import 'package:restaurant_app/features/ratings/presentation/controllers/rating_controller.dart';

void main() {
  group('Rating After Order Flow Integration Test', () {
    test('submits meal and driver ratings after order completion and verifies calculations', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final ratingController = container.read(ratingSubmissionControllerProvider.notifier);

      // 1. Submit rating for menu item
      final successItem = await ratingController.submitRating(
        targetId: 'item-kebda-1',
        targetType: RatingTargetType.menuItem,
        userId: 'usr-customer-1',
        userName: 'أحمد سعيد',
        score: 5.0,
        comment: 'أفضل كبدة إسكندراني',
      );
      expect(successItem, isTrue);

      final itemRatings = await container.read(targetRatingsProvider('item-kebda-1').future);
      expect(itemRatings, hasLength(1));
      expect(itemRatings.first.comment, 'أفضل كبدة إسكندراني');

      final itemAvg = await container.read(targetAverageScoreProvider('item-kebda-1').future);
      expect(itemAvg, 5.0);

      // 2. Submit rating for driver
      final successDriver = await ratingController.submitRating(
        targetId: 'drv-fast-1',
        targetType: RatingTargetType.driver,
        userId: 'usr-customer-1',
        userName: 'أحمد سعيد',
        score: 4.0,
        comment: 'توصيل سريع ولبق',
      );
      expect(successDriver, isTrue);

      final driverRatings = await container.read(targetRatingsProvider('drv-fast-1').future);
      expect(driverRatings, hasLength(1));
      expect(driverRatings.first.targetType, RatingTargetType.driver);
    });
  });
}
