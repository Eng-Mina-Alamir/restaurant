import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/menu/data/repositories/menu_repository_impl.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';

void main() {
  group('Menu Repository CRUD Tests', () {
    late MenuRepositoryImpl repository;

    setUp(() {
      repository = MenuRepositoryImpl();
    });

    test('fetches initial seeded menu', () async {
      final result = await repository.getMenu();
      expect(result.isRight, isTrue);
      final menu = result.when(onLeft: (_) => null, onRight: (m) => m);
      expect(menu, isNotNull);
      expect(menu!.items.isNotEmpty, isTrue);
      expect(menu.categories.isNotEmpty, isTrue);
    });

    test('adds new item and appends category if not present', () async {
      const newItem = MenuItem(
        id: 'item-new-1',
        categoryId: 'حلويات شرقية',
        name: 'كنافة نابلسية',
        description: 'كنافة بالجبن العكاوي والفستق',
        price: 32.0,
      );

      final result = await repository.addMenuItem(newItem);
      expect(result.isRight, isTrue);

      final menuRes = await repository.getMenu();
      final menu = menuRes.when(onLeft: (_) => null, onRight: (m) => m);
      expect(menu!.items.any((i) => i.id == 'item-new-1'), isTrue);
      expect(menu.categories.contains('حلويات شرقية'), isTrue);
    });

    test('updates existing item correctly', () async {
      final initialRes = await repository.getMenu();
      final firstItem = initialRes
          .when(onLeft: (_) => null, onRight: (m) => m)!
          .items
          .first;

      final updatedItem = firstItem.copyWith(
        price: 99.0,
        name: 'برجر ملكي معدل',
      );
      final result = await repository.updateMenuItem(updatedItem);
      expect(result.isRight, isTrue);

      final menuRes = await repository.getMenu();
      final item = menuRes
          .when(onLeft: (_) => null, onRight: (m) => m)!
          .items
          .firstWhere((i) => i.id == firstItem.id);
      expect(item.price, 99.0);
      expect(item.name, 'برجر ملكي معدل');
    });

    test('toggles availability status', () async {
      final initialRes = await repository.getMenu();
      final firstItem = initialRes
          .when(onLeft: (_) => null, onRight: (m) => m)!
          .items
          .first;

      final result = await repository.toggleAvailability(firstItem.id, false);
      expect(result.isRight, isTrue);

      final menuRes = await repository.getMenu();
      final item = menuRes
          .when(onLeft: (_) => null, onRight: (m) => m)!
          .items
          .firstWhere((i) => i.id == firstItem.id);
      expect(item.isAvailable, isFalse);
    });

    test('deletes menu item', () async {
      final initialRes = await repository.getMenu();
      final firstItem = initialRes
          .when(onLeft: (_) => null, onRight: (m) => m)!
          .items
          .first;

      await repository.deleteMenuItem(firstItem.id);

      final menuRes = await repository.getMenu();
      final exists = menuRes
          .when(onLeft: (_) => null, onRight: (m) => m)!
          .items
          .any((i) => i.id == firstItem.id);
      expect(exists, isFalse);
    });
  });
}
