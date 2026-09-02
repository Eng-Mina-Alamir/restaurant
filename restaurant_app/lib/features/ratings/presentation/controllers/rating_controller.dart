import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/app_config.dart';
import '../../../../core/data/app_cache.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../data/repositories/in_memory_rating_repository.dart';
import '../../data/repositories/supabase_rating_repository.dart';
import '../../domain/entities/rating_entity.dart';
import '../../domain/repositories/rating_repository.dart';

final ratingRepositoryProvider = Provider<RatingRepository>((ref) {
  if (AppConfig.useSupabase) {
    return SupabaseRatingRepository(
      supabase: ref.watch(supabaseClientProvider),
      cache: ref.watch(localCacheServiceProvider),
    );
  }
  return InMemoryRatingRepository();
});

/// Family provider for fetching ratings list for a target (item, driver, or restaurant).
final targetRatingsProvider = FutureProvider.family<List<RatingEntity>, String>(
  (ref, targetId) async {
    final repo = ref.watch(ratingRepositoryProvider);
    final result = await repo.getRatingsForTarget(targetId);
    return result.when(onLeft: (failure) => [], onRight: (list) => list);
  },
);

/// Family provider for fetching average score for a target.
final targetAverageScoreProvider = FutureProvider.family<double, String>((
  ref,
  targetId,
) async {
  final repo = ref.watch(ratingRepositoryProvider);
  final result = await repo.getAverageScore(targetId);
  return result.when(onLeft: (_) => 5.0, onRight: (score) => score);
});

class RatingSubmissionController extends StateNotifier<AsyncValue<void>> {
  RatingSubmissionController(this._repository, this._ref)
    : super(const AsyncValue.data(null));

  final RatingRepository _repository;
  final Ref _ref;

  Future<bool> submitRating({
    required String targetId,
    required RatingTargetType targetType,
    required String userId,
    required String userName,
    required double score,
    String? comment,
  }) async {
    state = const AsyncValue.loading();
    final rating = RatingEntity(
      id: '0',
      targetId: targetId,
      targetType: targetType,
      userId: userId,
      userName: userName,
      score: score,
      comment: comment,
      createdAt: DateTime.now(),
    );

    final result = await _repository.submitRating(rating);
    return result.when(
      onLeft: (failure) {
        state = AsyncValue.error(failure, StackTrace.current);
        return false;
      },
      onRight: (_) {
        state = const AsyncValue.data(null);
        _ref.invalidate(targetRatingsProvider(targetId));
        _ref.invalidate(targetAverageScoreProvider(targetId));
        return true;
      },
    );
  }
}

final ratingSubmissionControllerProvider =
    StateNotifierProvider<RatingSubmissionController, AsyncValue<void>>((ref) {
      return RatingSubmissionController(
        ref.watch(ratingRepositoryProvider),
        ref,
      );
    });
