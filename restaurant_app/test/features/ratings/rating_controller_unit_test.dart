import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/ratings/domain/entities/rating_entity.dart';
import 'package:restaurant_app/features/ratings/presentation/controllers/rating_controller.dart';
import '../../helpers/test_container.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = createTestContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('Rating Controller & Providers Unit Tests', () {
    test('targetRatingsProvider and targetAverageScoreProvider return initial data', () async {
      final ratings = await container.read(targetRatingsProvider('item-1').future);
      expect(ratings, isA<List<RatingEntity>>());

      final avg = await container.read(targetAverageScoreProvider('item-1').future);
      expect(avg, isA<double>());
    });

    test('submitRating adds a new rating successfully', () async {
      final controller = container.read(ratingSubmissionControllerProvider.notifier);

      final success = await controller.submitRating(
        targetId: 'item-1',
        targetType: RatingTargetType.menuItem,
        userId: 'user-10',
        userName: 'أحمد',
        score: 5.0,
        comment: 'أكل رائع جداً',
      );

      expect(success, isTrue);
      final ratings = await container.read(targetRatingsProvider('item-1').future);
      expect(ratings.any((r) => r.userName == 'أحمد' && r.comment == 'أكل رائع جداً'), isTrue);
    });
  });
}
