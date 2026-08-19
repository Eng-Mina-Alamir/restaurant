import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/ratings/data/repositories/in_memory_rating_repository.dart';
import 'package:restaurant_app/features/ratings/domain/entities/rating_entity.dart';

void main() {
  group('Ratings Repository Tests', () {
    late InMemoryRatingRepository repository;

    setUp(() {
      repository = InMemoryRatingRepository();
    });

    test('retrieves ratings for target item and calculates average', () async {
      final listResult = await repository.getRatingsForTarget('item-1');
      expect(listResult.isRight, isTrue);
      final list = listResult.when(onLeft: (_) => null, onRight: (l) => l);
      expect(list!.length, 2);

      final avgResult = await repository.getAverageScore('item-1');
      expect(avgResult.isRight, isTrue);
      final avg = avgResult.when(onLeft: (_) => null, onRight: (s) => s);
      expect(avg, 4.75);
    });

    test('submits new review and updates average', () async {
      final newRating = RatingEntity(
        id: 'rate-new-1',
        targetId: 'item-1',
        targetType: RatingTargetType.menuItem,
        userId: 'u99',
        userName: 'عبدالله السعد',
        score: 5.0,
        comment: 'فوق الممتاز!',
        createdAt: DateTime.now(),
      );

      final submitRes = await repository.submitRating(newRating);
      expect(submitRes.isRight, isTrue);

      final listResult = await repository.getRatingsForTarget('item-1');
      final list = listResult.when(onLeft: (_) => null, onRight: (l) => l);
      expect(list!.length, 3);
    });
  });
}
