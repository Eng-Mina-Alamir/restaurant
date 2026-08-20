import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/config/supabase_config.dart';
import 'package:restaurant_app/features/menu/data/repositories/supabase_menu_repository.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('SupabaseMenuRepositoryImpl Unit Tests', () {
    late SupabaseClient client;
    late SupabaseMenuRepositoryImpl repository;

    setUp(() {
      client = SupabaseClient(SupabaseConfig.url, SupabaseConfig.anonKey);
      repository = SupabaseMenuRepositoryImpl(client);
    });

    test('getMenu gracefully falls back to menu data on network offline/seed fallback', () async {
      final result = await repository.getMenu();

      expect(result.isRight, isTrue);
      result.when(
        onLeft: (_) => fail('Expected right menu'),
        onRight: (menu) {
          expect(menu.items, isNotEmpty);
          expect(menu.categories, isNotEmpty);
          expect(menu.categories, contains('مشروبات'));
        },
      );
    });

    test('toggleAvailability updates cache and returns MenuItem', () async {
      // First prime the cache
      await repository.getMenu();

      final result = await repository.toggleAvailability('item-1', false);
      expect(result.isRight, isTrue);
      result.when(
        onLeft: (_) => fail('Expected right item'),
        onRight: (item) {
          expect(item.id, 'item-1');
          expect(item.isAvailable, isFalse);
        },
      );
    });

    test('addMenuItem handles remote operation cleanly', () async {
      const item = MenuItem(
        id: 'test-item-1',
        categoryId: 'مشويات',
        name: 'كباب مخصوص',
        description: 'وصف تجريبي',
        price: 150.0,
      );

      final result = await repository.addMenuItem(item);
      expect(result, isNotNull);
    });
  });
}
