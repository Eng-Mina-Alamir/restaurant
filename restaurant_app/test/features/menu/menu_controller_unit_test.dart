import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/menu/presentation/controllers/menu_controller.dart';

void main() {
  group('filterMenu Utility Unit Tests', () {
    const vegSalad = MenuItem(
      id: '1',
      categoryId: 'salads',
      name: 'سلطة خضراء',
      description: 'سلطة طازجة مع زيت زيتون',
      price: 20.0,
      isVegetarian: true,
      isSpicy: false,
    );

    const spicyChicken = MenuItem(
      id: '2',
      categoryId: 'main',
      name: 'دجاج حار',
      description: 'دجاج بتتبيلة فلفل حار',
      price: 55.0,
      isVegetarian: false,
      isSpicy: true,
    );

    const regularBurger = MenuItem(
      id: '3',
      categoryId: 'main',
      name: 'برجر كلاسيك',
      description: 'شريحة لحم بقري',
      price: 45.0,
      isVegetarian: false,
      isSpicy: false,
    );

    const menu = Menu(
      restaurantId: 'r1',
      categories: ['salads', 'main'],
      items: [vegSalad, spicyChicken, regularBurger],
    );

    test(
      'returns all items when category is kAllCategoriesFilter and no query/diet',
      () {
        final result = filterMenu(menu, kAllCategoriesFilter);
        expect(result, hasLength(3));
      },
    );

    test('filters by category accurately', () {
      final salads = filterMenu(menu, 'salads');
      expect(salads, hasLength(1));
      expect(salads.first.id, '1');

      final mains = filterMenu(menu, 'main');
      expect(mains, hasLength(2));
    });

    test('filters by search query matching name or description', () {
      final byName = filterMenu(menu, kAllCategoriesFilter, 'برجر');
      expect(byName, hasLength(1));
      expect(byName.first.id, '3');

      final byDesc = filterMenu(menu, kAllCategoriesFilter, 'زيت زيتون');
      expect(byDesc, hasLength(1));
      expect(byDesc.first.id, '1');
    });

    test('filters by vegetarian dietary filter', () {
      final vegetarian = filterMenu(
        menu,
        kAllCategoriesFilter,
        '',
        MenuDietFilter.vegetarian,
      );
      expect(vegetarian, hasLength(1));
      expect(vegetarian.first.id, '1');
    });

    test('filters by spicy dietary filter', () {
      final spicy = filterMenu(
        menu,
        kAllCategoriesFilter,
        '',
        MenuDietFilter.spicy,
      );
      expect(spicy, hasLength(1));
      expect(spicy.first.id, '2');
    });

    test('combined category + query + diet restrictions', () {
      final result = filterMenu(menu, 'main', 'دجاج', MenuDietFilter.spicy);
      expect(result, hasLength(1));
      expect(result.first.id, '2');

      final noneFound = filterMenu(menu, 'salads', 'دجاج', MenuDietFilter.none);
      expect(noneFound, isEmpty);
    });

    test('handles null menu safely', () {
      final result = filterMenu(null, kAllCategoriesFilter);
      expect(result, isEmpty);
    });
  });
}
