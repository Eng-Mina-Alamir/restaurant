import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/errors/either.dart';
import 'package:restaurant_app/core/errors/failures.dart';
import 'package:restaurant_app/features/ratings/domain/entities/rating_entity.dart';
import 'package:restaurant_app/features/ratings/domain/repositories/rating_repository.dart';
import 'package:restaurant_app/features/ratings/presentation/controllers/rating_controller.dart';

class _FakeRatingRepository implements RatingRepository {
  final List<RatingEntity> ratings = [];
  bool shouldFail = false;

  @override
  Future<Either<Failure, RatingEntity>> submitRating(
    RatingEntity rating,
  ) async {
    if (shouldFail) {
      return const Left(ValidationFailure('فشل في إرسال التقييم'));
    }
    ratings.add(rating);
    return Right(rating);
  }

  @override
  Future<Either<Failure, List<RatingEntity>>> getRatingsForTarget(
    String targetId,
  ) async {
    return Right(ratings.where((r) => r.targetId == targetId).toList());
  }

  @override
  Future<Either<Failure, double>> getAverageScore(String targetId) async {
    final list = ratings.where((r) => r.targetId == targetId).toList();
    if (list.isEmpty) return const Right(5.0);
    final avg = list.fold<double>(0, (sum, r) => sum + r.score) / list.length;
    return Right(avg);
  }
}

void main() {
  group('RatingEntity and RatingSubmissionController Tests (v2)', () {
    test('RatingTargetType labels', () {
      expect(RatingTargetType.menuItem.labelAr, 'تقييم الوجبة');
      expect(RatingTargetType.driver.labelAr, 'تقييم السائق');
      expect(RatingTargetType.restaurant.labelAr, 'تقييم المطعم');
    });

    test('RatingEntity JSON round-trip serialization', () {
      final now = DateTime(2026, 8, 19, 16, 0);
      final rating = RatingEntity(
        id: 'rate-10',
        targetId: 'item-burger',
        targetType: RatingTargetType.menuItem,
        userId: 'usr-1',
        userName: 'كريم',
        score: 4.5,
        comment: 'لذيذ جداً',
        createdAt: now,
      );

      final json = rating.toJson();
      expect(json['targetType'], 'menuItem');
      expect(json['score'], 4.5);

      final deserialized = RatingEntity.fromJson(json);
      expect(deserialized.id, 'rate-10');
      expect(deserialized.targetType, RatingTargetType.menuItem);
      expect(deserialized.score, 4.5);
      expect(deserialized.comment, 'لذيذ جداً');
    });

    test(
      'submitRating success updates state and invalidates target providers',
      () async {
        final repo = _FakeRatingRepository();
        final container = ProviderContainer(
          overrides: [ratingRepositoryProvider.overrideWithValue(repo)],
        );
        addTearDown(container.dispose);

        final controller = container.read(
          ratingSubmissionControllerProvider.notifier,
        );

        final success = await controller.submitRating(
          targetId: 'item-burger',
          targetType: RatingTargetType.menuItem,
          userId: 'usr-1',
          userName: 'كريم',
          score: 5.0,
          comment: 'ممتاز',
        );

        expect(success, isTrue);
        expect(repo.ratings, hasLength(1));
        expect(
          container.read(ratingSubmissionControllerProvider).hasError,
          isFalse,
        );
      },
    );

    test('submitRating failure sets error state and returns false', () async {
      final repo = _FakeRatingRepository();
      repo.shouldFail = true;
      final container = ProviderContainer(
        overrides: [ratingRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final controller = container.read(
        ratingSubmissionControllerProvider.notifier,
      );

      final success = await controller.submitRating(
        targetId: 'item-burger',
        targetType: RatingTargetType.menuItem,
        userId: 'usr-1',
        userName: 'كريم',
        score: 5.0,
      );

      expect(success, isFalse);
      expect(
        container.read(ratingSubmissionControllerProvider).hasError,
        isTrue,
      );
    });
  });
}
