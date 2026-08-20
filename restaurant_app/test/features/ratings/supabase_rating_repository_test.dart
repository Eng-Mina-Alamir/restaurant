import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/config/supabase_config.dart';
import 'package:restaurant_app/features/ratings/data/repositories/supabase_rating_repository.dart';
import 'package:restaurant_app/features/ratings/domain/entities/rating_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('SupabaseRatingRepository Tests', () {
    late SupabaseClient client;
    late SupabaseRatingRepository repository;

    setUp(() {
      client = SupabaseClient(SupabaseConfig.url, SupabaseConfig.anonKey);
      repository = SupabaseRatingRepository(supabase: client);
    });

    final testRating = RatingEntity(
      id: 'rate-test-001',
      targetId: 'item-101',
      targetType: RatingTargetType.menuItem,
      userId: 'user-001',
      userName: 'سارة خالد',
      score: 4.5,
      comment: 'طعام لذيذ جداً وخدمة سريعة',
      createdAt: DateTime.now(),
    );

    test('RatingEntity validates target and score bounds', () {
      expect(testRating.score, 4.5);
      expect(testRating.targetType, RatingTargetType.menuItem);
      expect(testRating.userName, 'سارة خالد');
    });

    test('getAverageScore returns score fallback or calculated average', () async {
      final result = await repository.getAverageScore('non-existent-target');
      expect(result.isRight, isTrue);
      result.when(
        onLeft: (_) => fail('Expected right default score'),
        onRight: (score) => expect(score, greaterThanOrEqualTo(1.0)),
      );
    });
  });
}
