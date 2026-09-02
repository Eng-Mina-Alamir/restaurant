import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/supabase_config.dart';
import '../../../../core/data/local_cache_service.dart';
import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/rating_entity.dart';
import '../../domain/repositories/rating_repository.dart';

class SupabaseRatingRepository implements RatingRepository {
  SupabaseRatingRepository({
    required SupabaseClient supabase,
    LocalCacheService? cache,
  })  : _supabase = supabase,
        _cache = cache;

  final SupabaseClient _supabase;
  final LocalCacheService? _cache;

  static const String _ratingCacheKeyPrefix = 'ratings_';

  @override
  Future<Either<Failure, List<RatingEntity>>> getRatingsForTarget(
    String targetId,
  ) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.ratingsTable)
          .select()
          .eq('target_id', targetId)
          .order('created_at', ascending: false)
          .limit(50);

      final List<RatingEntity> ratings = [];
      for (final raw in (response as List)) {
        final map = Map<String, dynamic>.from(raw as Map);
        ratings.add(_mapToRatingEntity(map));
      }

      final cache = _cache;
      if (cache != null) {
        await cache.writeList(
          '$_ratingCacheKeyPrefix$targetId',
          ratings.map((r) => {
            'id': r.id,
            'targetId': r.targetId,
            'targetType': r.targetType.name,
            'userId': r.userId,
            'userName': r.userName,
            'score': r.score,
            'comment': r.comment,
            'createdAt': r.createdAt.toIso8601String(),
          }).toList(),
        );
      }

      return Right(ratings);
    } catch (e, st) {
      AppLogger.warning('Supabase getRatingsForTarget fallback: $e', error: e, stackTrace: st);
      final cache = _cache;
      if (cache != null) {
        final cached = cache.readList('$_ratingCacheKeyPrefix$targetId');
        if (cached.isNotEmpty) {
          final list = cached.map((map) => RatingEntity(
            id: map['id']?.toString() ?? '',
            targetId: map['targetId'] as String? ?? targetId,
            targetType: RatingTargetType.values.firstWhere(
              (t) => t.name == map['targetType'],
              orElse: () => RatingTargetType.menuItem,
            ),
            userId: map['userId'] as String? ?? '',
            userName: map['userName'] as String? ?? 'عميل',
            score: (map['score'] as num?)?.toDouble() ?? 5.0,
            comment: map['comment'] as String? ?? '',
            createdAt: map['createdAt'] != null
                ? DateTime.parse(map['createdAt'] as String)
                : DateTime.now(),
          )).toList();
          return Right(list);
        }
      }
      return const Right([]);
    }
  }

  @override
  Future<Either<Failure, RatingEntity>> submitRating(
    RatingEntity rating,
  ) async {
    try {
      final currentUid = _supabase.auth.currentUser?.id ?? rating.userId;
      final payload = {
        'target_id': rating.targetId,
        'target_type': rating.targetType.name,
        'user_id': currentUid,
        'user_name': rating.userName,
        'score': rating.score,
        'comment': rating.comment,
        'created_at': rating.createdAt.toIso8601String(),
        'restaurant_id': SupabaseConfig.defaultRestaurantId,
      };

      final response = await _supabase
          .from(SupabaseConfig.ratingsTable)
          .insert(payload)
          .select()
          .single();

      final created = rating.copyWith(
        id: response['id']?.toString() ?? rating.id,
      );
      return Right(created);
    } catch (e, st) {
      AppLogger.error('Supabase submitRating error: $e', error: e, stackTrace: st);
      return Left(ServerFailure('فشل إرسال التقييم: $e'));
    }
  }

  @override
  Future<Either<Failure, double>> getAverageScore(String targetId) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.ratingsTable)
          .select('score')
          .eq('target_id', targetId)
          .limit(500);

      final list = (response as List);
      if (list.isEmpty) return const Right(5.0);

      double sum = 0.0;
      for (final item in list) {
        final map = Map<String, dynamic>.from(item as Map);
        sum += (map['score'] as num?)?.toDouble() ?? 5.0;
      }
      return Right(sum / list.length);
    } catch (e, st) {
      AppLogger.warning('Supabase getAverageScore fallback: $e', error: e, stackTrace: st);
      return const Right(5.0);
    }
  }

  RatingEntity _mapToRatingEntity(Map<String, dynamic> map) {
    final typeStr = map['target_type'] as String? ?? 'menuItem';
    final type = RatingTargetType.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () => RatingTargetType.menuItem,
    );

    return RatingEntity(
      id: map['id']?.toString() ?? '',
      targetId: map['target_id']?.toString() ?? '',
      targetType: type,
      userId: map['user_id']?.toString() ?? '',
      userName: map['user_name'] as String? ?? 'عميل',
      score: (map['score'] as num?)?.toDouble() ?? 5.0,
      comment: map['comment'] as String? ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
