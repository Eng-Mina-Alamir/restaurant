import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';

void main() {
  group('MenuItem and Modifiers Entity Tests', () {
    test('MenuModifierOption serialization and defaults', () {
      const option = MenuModifierOption(
        id: 'opt-1',
        name: 'جبنة إضافية',
        extraPrice: 10.0,
      );

      expect(option.isAvailable, isTrue);
      final json = option.toJson();
      expect(json['id'], 'opt-1');
      expect(json['extraPrice'], 10.0);

      final deserialized = MenuModifierOption.fromJson(json);
      expect(deserialized.name, 'جبنة إضافية');
      expect(deserialized.extraPrice, 10.0);
    });

    test('MenuModifierGroup serialization and properties', () {
      const group = MenuModifierGroup(
        id: 'grp-1',
        title: 'الإضافات',
        isRequired: true,
        maxSelection: 2,
        options: [
          MenuModifierOption(id: 'o1', name: 'صوص باربيكيو', extraPrice: 5.0),
          MenuModifierOption(id: 'o2', name: 'مايونيز بالثوم', extraPrice: 5.0),
        ],
      );

      final json = group.toJson();
      expect(json['title'], 'الإضافات');
      expect(json['isRequired'], isTrue);
      expect(json['maxSelection'], 2);
      expect(json['options'], hasLength(2));

      final deserialized = MenuModifierGroup.fromJson(json);
      expect(deserialized.options.first.name, 'صوص باربيكيو');
    });

    test('MenuItem round-trip serialization with all flags', () {
      const item = MenuItem(
        id: 'item-10',
        categoryId: 'cat-main',
        name: 'كباب مشوي',
        description: 'لحم ضأن طازج مشوي على الفحم',
        price: 85.0,
        imageUrl: 'https://example.com/kebab.jpg',
        isAvailable: true,
        isVegetarian: false,
        isSpicy: true,
        preparationTime: 20.0,
        rating: 4.8,
        orderCount: 150,
      );

      final json = item.toJson();
      expect(json['id'], 'item-10');
      expect(json['isSpicy'], isTrue);
      expect(json['rating'], 4.8);

      final deserialized = MenuItem.fromJson(json);
      expect(deserialized.name, item.name);
      expect(deserialized.isSpicy, isTrue);
      expect(deserialized.price, 85.0);
      expect(deserialized.orderCount, 150);
    });
  });
}
