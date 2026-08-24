import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/errors/either.dart';
import 'package:restaurant_app/core/errors/failures.dart';
import 'package:restaurant_app/features/ratings/data/repositories/in_memory_rating_repository.dart';
import 'package:restaurant_app/features/ratings/domain/entities/rating_entity.dart';

void main() {
  group('Rating Repository & Entity Unit Tests', () {
    late InMemoryRatingRepository repository;

    setUp(() {
      repository = InMemoryRatingRepository();
    });

    test(
      'getRatingsForTarget returns seeded reviews sorted descending',
      () async {
        final result = await repository.getRatingsForTarget('item-1');
        expect(result.isRight, isTrue);
        final ratings = (result as Right<Failure, List<RatingEntity>>).value;
        expect(ratings.length, 2);
        expect(ratings.first.score, isNotNull);
      },
    );

    test('submitRating adds new review and affects average score', () async {
      final newRating = RatingEntity(
        id: 'rate-new',
        targetId: 'item-1',
        targetType: RatingTargetType.menuItem,
        userId: 'u99',
        userName: 'خالد',
        score: 5.0,
        comment: 'ممتاز',
        createdAt: DateTime.now(),
      );

      final submitResult = await repository.submitRating(newRating);
      expect(submitResult.isRight, isTrue);

      final avgResult = await repository.getAverageScore('item-1');
      expect(avgResult.isRight, isTrue);
      final avg = (avgResult as Right<Failure, double>).value;
      expect(avg, greaterThan(4.5));
    });

    test('getAverageScore returns 5.0 default when no ratings exist', () async {
      final avgResult = await repository.getAverageScore('non-existent-target');
      expect(avgResult.isRight, isTrue);
      final avg = (avgResult as Right<Failure, double>).value;
      expect(avg, 5.0);
    });
  });
}
