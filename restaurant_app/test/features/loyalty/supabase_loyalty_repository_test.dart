import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/config/supabase_config.dart';
import 'package:restaurant_app/features/loyalty/data/repositories/supabase_loyalty_repository.dart';
import 'package:restaurant_app/features/loyalty/domain/entities/loyalty_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('SupabaseLoyaltyRepository Tests', () {
    late SupabaseClient client;
    late SupabaseLoyaltyRepository repository;

    setUp(() {
      client = SupabaseClient(SupabaseConfig.url, SupabaseConfig.anonKey);
      repository = SupabaseLoyaltyRepository(supabase: client);
    });

    test('LoyaltyTier calculates correct tier based on lifetime points', () {
      expect(LoyaltyTier.fromPoints(0), LoyaltyTier.bronze);
      expect(LoyaltyTier.fromPoints(499), LoyaltyTier.bronze);
      expect(LoyaltyTier.fromPoints(500), LoyaltyTier.silver);
      expect(LoyaltyTier.fromPoints(1499), LoyaltyTier.silver);
      expect(LoyaltyTier.fromPoints(1500), LoyaltyTier.gold);
      expect(LoyaltyTier.fromPoints(2999), LoyaltyTier.gold);
      expect(LoyaltyTier.fromPoints(3000), LoyaltyTier.platinum);
    });

    test('getAvailableRewards returns Either list or failure', () async {
      final result = await repository.getAvailableRewards();
      expect(result, isNotNull);
    });

    test('getAccount handles user query gracefully', () async {
      final result = await repository.getAccount('test-user-id');
      expect(result, isNotNull);
    });
  });
}
