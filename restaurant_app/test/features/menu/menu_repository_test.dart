import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_app/features/menu/data/repositories/menu_repository_impl.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu.dart';

void main() {
  final menuRepository = MenuRepositoryImpl();

  group('MenuRepository', () {
    test(
      'returns seeded menu with at least 2 categories and 3 items',
      () async {
        final result = await menuRepository.getMenu();
        final menu = result.when<Menu?>(
          onLeft: (failure) => null,
          onRight: (value) => value,
        );
        expect(menu, isNotNull);
        expect(menu!.categories.length, greaterThanOrEqualTo(2));
        expect(menu.items.length, greaterThanOrEqualTo(3));
      },
    );

    test('seeded items carry valid modifier groups', () async {
      final result = await menuRepository.getMenu();
      final menu = result.when<Menu?>(
        onLeft: (failure) => null,
        onRight: (value) => value,
      );

      expect(menu, isNotNull);
      final withModifiers = menu!.items
          .where((item) => item.modifierGroups.isNotEmpty)
          .toList();
      expect(withModifiers, isNotEmpty);
      expect(withModifiers.first.modifierGroups.first.options, isNotEmpty);
    });

    test('itemsIn filters by categoryId', () async {
      final result = await menuRepository.getMenu();
      final menu = result.when<Menu?>(
        onLeft: (failure) => null,
        onRight: (value) => value,
      );
      final category = menu!.categories.first;
      final items = menu.itemsIn(category);
      expect(items, isNotEmpty);
      expect(items.every((item) => item.categoryId == category), isTrue);
    });
  });
}
