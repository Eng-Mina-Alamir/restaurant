import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/supabase_config.dart';
import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/rating_entity.dart';
import '../../domain/repositories/rating_repository.dart';

class SupabaseRatingRepository implements RatingRepository {
  SupabaseRatingRepository({required SupabaseClient supabase})
    : _supabase = supabase;

  final SupabaseClient _supabase;

  final List<RatingEntity> _cachedRatings = [];

  @override
  Future<Either<Failure, List<RatingEntity>>> getRatingsForTarget(
    String targetId,
  ) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.ratingsTable)
          .select()
          .eq('target_id', targetId)
          .order('created_at', ascending: false);

      final List<RatingEntity> ratings = [];
      for (final raw in (response as List)) {
        final map = Map<String, dynamic>.from(raw as Map);
        ratings.add(_mapToRatingEntity(map));
      }
      return Right(ratings);
    } catch (e, st) {
      AppLogger.warning(
        'Supabase getRatingsForTarget fallback: $e',
        error: e,
        stackTrace: st,
      );
      final local = _cachedRatings
          .where((r) => r.targetId == targetId)
          .toList();
      return Right(local);
    }
  }

  @override
  Future<Either<Failure, RatingEntity>> submitRating(
    RatingEntity rating,
  ) async {
    try {
      final currentUid = _supabase.auth.currentUser?.id ?? rating.userId;
      final payload = {
        'id': rating.id,
        'target_id': rating.targetId,
        'target_type': rating.targetType.name,
        'user_id': currentUid,
        'user_name': rating.userName,
        'score': rating.score,
        'comment': rating.comment,
        'created_at': rating.createdAt.toIso8601String(),
      };

      await _supabase.from(SupabaseConfig.ratingsTable).insert(payload);
      _cachedRatings.insert(0, rating);
      return Right(rating);
    } catch (e, st) {
      AppLogger.warning(
        'Supabase submitRating fallback: $e',
        error: e,
        stackTrace: st,
      );
      _cachedRatings.insert(0, rating);
      return Right(rating);
    }
  }

  @override
  Future<Either<Failure, double>> getAverageScore(String targetId) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.ratingsTable)
          .select('score')
          .eq('target_id', targetId);

      final list = (response as List);
      if (list.isEmpty) return const Right(5.0);

      double sum = 0.0;
      for (final item in list) {
        sum += (item['score'] as num?)?.toDouble() ?? 5.0;
      }
      return Right(sum / list.length);
    } catch (e, st) {
      AppLogger.error(
        'Supabase getAverageScore error',
        error: e,
        stackTrace: st,
      );
      return const Right(5.0);
    }
  }

  RatingEntity _mapToRatingEntity(Map<String, dynamic> map) {
    final targetTypeStr = map['target_type'] as String? ?? 'menuItem';
    final targetType = RatingTargetType.values.firstWhere(
      (e) => e.name == targetTypeStr,
      orElse: () => RatingTargetType.menuItem,
    );

    return RatingEntity(
      id: map['id']?.toString() ?? '',
      targetId: map['target_id'] as String? ?? '',
      targetType: targetType,
      userId: map['user_id']?.toString() ?? '',
      userName: map['user_name'] as String? ?? 'عميل',
      score: (map['score'] as num?)?.toDouble() ?? 5.0,
      comment: map['comment'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
