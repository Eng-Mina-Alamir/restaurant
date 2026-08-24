import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';

void main() {
  group('CartItem Entity Tests', () {
    const pizza = MenuItem(
      id: 'pizza-1',
      categoryId: 'pizza',
      name: 'بيتزا مارجريتا',
      description: 'جبنة وطماطم',
      price: 50.0,
    );

    const extraCheese = MenuModifierOption(
      id: 'mod-cheese',
      name: 'جبنة زيادة',
      extraPrice: 10.0,
    );

    const olives = MenuModifierOption(
      id: 'mod-olives',
      name: 'زيتون',
      extraPrice: 5.0,
    );

    test(
      'unitPrice and linePrice calculate modifiers and quantity correctly',
      () {
        const cartItem = CartItem(
          menuItem: pizza,
          quantity: 3,
          selectedModifiers: [extraCheese, olives],
        );

        // unitPrice = 50 + 10 + 5 = 65
        expect(cartItem.unitPrice, 65.0);
        // linePrice = 65 * 3 = 195
        expect(cartItem.linePrice, 195.0);
      },
    );

    test(
      'configKey is deterministic regardless of modifier insertion order',
      () {
        const itemA = CartItem(
          menuItem: pizza,
          quantity: 1,
          selectedModifiers: [extraCheese, olives],
        );

        const itemB = CartItem(
          menuItem: pizza,
          quantity: 2,
          selectedModifiers: [olives, extraCheese],
        );

        expect(itemA.configKey, itemB.configKey);
        expect(itemA.configKey, 'pizza-1|mod-cheese,mod-olives');
      },
    );

    test('round-trip JSON serialization', () {
      final json = {
        'menuItem': pizza.toJson(),
        'quantity': 2,
        'selectedModifiers': [extraCheese.toJson()],
        'specialNotes': 'بدون شطة',
      };

      final deserialized = CartItem.fromJson(json);

      expect(deserialized.menuItem.id, 'pizza-1');
      expect(deserialized.quantity, 2);
      expect(deserialized.selectedModifiers, hasLength(1));
      expect(deserialized.specialNotes, 'بدون شطة');
      expect(deserialized.unitPrice, 60.0);
    });
  });
}
