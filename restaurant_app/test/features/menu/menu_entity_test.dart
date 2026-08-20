import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';

void main() {
  group('Menu Aggregate Entity Tests', () {
    const item1 = MenuItem(
      id: 'i1',
      categoryId: 'grills',
      name: 'كفتة',
      description: 'كفتة مشوية',
      price: 60.0,
    );

    const item2 = MenuItem(
      id: 'i2',
      categoryId: 'appetizers',
      name: 'طحينة',
      description: 'سلطة طحينة',
      price: 15.0,
    );

    test('itemsIn filters correctly by categoryId', () {
      const menu = Menu(
        restaurantId: 'rest-1',
        categories: ['grills', 'appetizers'],
        items: [item1, item2],
      );

      final grills = menu.itemsIn('grills');
      expect(grills, hasLength(1));
      expect(grills.first.id, 'i1');

      final appetizers = menu.itemsIn('appetizers');
      expect(appetizers, hasLength(1));
      expect(appetizers.first.id, 'i2');

      final drinks = menu.itemsIn('drinks');
      expect(drinks, isEmpty);
    });

    test('round-trip JSON serialization for Menu', () {
      final json = {
        'restaurantId': 'rest-1',
        'categories': ['grills', 'appetizers'],
        'items': [item1.toJson(), item2.toJson()],
      };

      final deserialized = Menu.fromJson(json);
      expect(deserialized.restaurantId, 'rest-1');
      expect(deserialized.items, hasLength(2));
      expect(deserialized.categories, containsAll(['grills', 'appetizers']));
    });
  });
}
