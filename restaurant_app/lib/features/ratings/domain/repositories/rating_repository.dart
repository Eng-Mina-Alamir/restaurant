import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/rating_entity.dart';

abstract class RatingRepository {
  Future<Either<Failure, List<RatingEntity>>> getRatingsForTarget(
    String targetId,
  );
  Future<Either<Failure, RatingEntity>> submitRating(RatingEntity rating);
  Future<Either<Failure, double>> getAverageScore(String targetId);
}
