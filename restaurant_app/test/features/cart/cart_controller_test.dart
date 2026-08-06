import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';

void main() {
  const burger = MenuItem(
    id: 'b1',
    categoryId: 'برجر',
    name: 'برجر',
    description: 'وصف',
    price: 28,
  );
  const cheese = MenuModifierOption(id: 'c1', name: 'جبنة', extraPrice: 4);

  late ProviderContainer container;
  late CartController controller;

  setUp(() {
    container = ProviderContainer();
    controller = container.read(cartControllerProvider.notifier);
  });

  tearDown(() => container.dispose());

  group('CartController', () {
    test('starts empty with zero totals', () {
      expect(controller.state, isEmpty);
      expect(controller.unitCount, 0);
      expect(controller.totals.totalAmount, 0);
    });

    test('addItem appends new configuration', () {
      controller.addItem(const CartItem(menuItem: burger, quantity: 2));
      expect(controller.state.length, 1);
      expect(controller.unitCount, 2);
    });

    test('addItem merges same configuration by quantity', () {
      controller.addItem(const CartItem(menuItem: burger, quantity: 1));
      controller.addItem(const CartItem(menuItem: burger, quantity: 1));
      expect(controller.state.length, 1);
      expect(controller.state.first.quantity, 2);
    });

    test('different modifiers create distinct lines', () {
      controller.addItem(const CartItem(menuItem: burger));
      controller.addItem(
        const CartItem(menuItem: burger, selectedModifiers: [cheese]),
      );
      expect(controller.state.length, 2);
    });

    test('increment/decrement update quantity', () {
      controller.addItem(const CartItem(menuItem: burger));
      final key = controller.state.first.configKey;
      controller.increment(key);
      expect(controller.state.first.quantity, 2);
      controller.decrement(key);
      expect(controller.state.first.quantity, 1);
    });

    test('decrement at quantity 1 removes the line', () {
      controller.addItem(const CartItem(menuItem: burger));
      final key = controller.state.first.configKey;
      controller.decrement(key);
      expect(controller.state, isEmpty);
    });

    test('removeItem clears a specific line', () {
      controller.addItem(const CartItem(menuItem: burger));
      final key = controller.state.first.configKey;
      controller.removeItem(key);
      expect(controller.state, isEmpty);
    });

    test('totals reflect mutations', () {
      controller.addItem(const CartItem(menuItem: burger, quantity: 2));
      expect(controller.totals.subtotal, 56.0);
      expect(controller.totals.taxAmount, closeTo(8.4, 0.001));
      expect(controller.totals.totalAmount, closeTo(64.4, 0.001));
    });

    test('clear empties the cart', () {
      controller.addItem(const CartItem(menuItem: burger));
      controller.clear();
      expect(controller.state, isEmpty);
    });
  });
}
