import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/menu/data/menu_seed_data.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';

void main() {
  group('CartController availability guard', () {
    test('rejects unavailable items so they cannot be added', () {
      final controller = CartController();

      const unavailable = MenuItem(
        id: 'unavailable-1',
        categoryId: 'x',
        name: 'نفدت',
        description: 'd',
        price: 5,
        isAvailable: false,
      );

      controller.addItem(const CartItem(menuItem: unavailable, quantity: 1));

      expect(controller.state, isEmpty);
      expect(controller.unitCount, 0);
    });

    test('allows available items', () {
      final controller = CartController();
      const available = MenuItem(
        id: 'available-1',
        categoryId: 'x',
        name: 'متوفر',
        description: description,
        price: 5,
        isAvailable: true,
      );
      controller.addItem(const CartItem(menuItem: available, quantity: 2));
      expect(controller.unitCount, 2);
    });
  });

  group('MenuSeedData', () {
    test('includes the desserts category and an unavailable item', () {
      expect(MenuSeedData.categories, contains('حلويات'));
      final desserts = MenuSeedData.items.where(
        (i) => i.categoryId == 'حلويات',
      );
      expect(desserts, isNotEmpty);
      expect(MenuSeedData.items.any((i) => !i.isAvailable), isTrue);
    });

    test('new columns are shared across buildMenu aggregate', () {
      final menu = MenuSeedData.buildMenu();
      expect(menu.categories, contains('حلويات'));
      expect(
        menu.items.length,
        greaterThanOrEqualTo(MenuSeedData.items.length),
      );
    });
  });
}

const description = 'وصف المنتج';
