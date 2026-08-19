import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/rating_entity.dart';
import '../../domain/repositories/rating_repository.dart';

class InMemoryRatingRepository implements RatingRepository {
  InMemoryRatingRepository() {
    _seed();
  }

  final List<RatingEntity> _ratings = [];

  void _seed() {
    _ratings.addAll([
      RatingEntity(
        id: 'rate-1',
        targetId: 'item-1',
        targetType: RatingTargetType.menuItem,
        userId: 'u1',
        userName: 'فهد السبيعي',
        score: 5.0,
        comment: 'طعم لا يقاوم، اللحم طري والخبز طازج جداً!',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      RatingEntity(
        id: 'rate-2',
        targetId: 'item-1',
        targetType: RatingTargetType.menuItem,
        userId: 'u2',
        userName: 'نورة المنصور',
        score: 4.5,
        comment: 'لذيذ جداً والتوصيل كان سريعاً.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      RatingEntity(
        id: 'rate-3',
        targetId: 'driver-demo',
        targetType: RatingTargetType.driver,
        userId: 'u3',
        userName: 'سلطان القحطاني',
        score: 5.0,
        comment: 'سائق محترم وسريع جداً.',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
    ]);
  }

  @override
  Future<Either<Failure, List<RatingEntity>>> getRatingsForTarget(
    String targetId,
  ) async {
    final list = _ratings.where((r) => r.targetId == targetId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Right<Failure, List<RatingEntity>>(list);
  }

  @override
  Future<Either<Failure, RatingEntity>> submitRating(
    RatingEntity rating,
  ) async {
    _ratings.add(rating);
    return Right<Failure, RatingEntity>(rating);
  }

  @override
  Future<Either<Failure, double>> getAverageScore(String targetId) async {
    final list = _ratings.where((r) => r.targetId == targetId).toList();
    if (list.isEmpty) return const Right<Failure, double>(5.0);
    final sum = list.fold<double>(0.0, (acc, r) => acc + r.score);
    return Right<Failure, double>(sum / list.length);
  }
}
