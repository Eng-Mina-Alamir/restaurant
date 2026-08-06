import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_app/features/menu/data/menu_seed_data.dart';
import 'package:restaurant_app/features/menu/presentation/controllers/menu_controller.dart';

void main() {
  final menu = MenuSeedData.buildMenu();

  test('filterMenu shows everything when no category or query', () {
    final items = filterMenu(menu, kAllCategoriesFilter);
    expect(items.length, menu.items.length);
  });

  test('filterMenu narrows by category', () {
    final items = filterMenu(menu, 'حلويات');
    expect(items, isNotEmpty);
    expect(items.every((i) => i.categoryId == 'حلويات'), isTrue);
  });

  test('filterMenu narrows by search text matching name', () {
    final items = filterMenu(menu, kAllCategoriesFilter, 'برجر');
    expect(items, isNotEmpty);
    expect(items.any((i) => i.name.contains('برجر')), isTrue);
  });

  test('filterMenu combines category and search query', () {
    final items = filterMenu(menu, 'مشروبات', 'برتقال');
    expect(items.length, 1);
    expect(items.first.name, contains('برتقال'));
  });

  test('filterMenu returns empty for a non-matching query', () {
    final items = filterMenu(menu, kAllCategoriesFilter, 'xyz-not-found');
    expect(items, isEmpty);
  });
}
