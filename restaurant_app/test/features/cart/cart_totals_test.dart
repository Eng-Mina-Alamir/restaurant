import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_app/features/cart/domain/cart_totals.dart';
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
  const bacon = MenuModifierOption(id: 'bx', name: 'لحم مقدد', extraPrice: 6);

  group('CartItem', () {
    test('unitPrice = base price + modifier surcharges', () {
      const item = CartItem(
        menuItem: burger,
        selectedModifiers: [cheese, bacon],
      );
      expect(item.unitPrice, 38.0);
    });

    test('linePrice scales with quantity', () {
      const item = CartItem(
        menuItem: burger,
        quantity: 3,
        selectedModifiers: [cheese],
      );
      expect(item.unitPrice, 32.0);
      expect(item.linePrice, 96.0);
    });

    test('configKey depends on item and sorted modifier ids', () {
      const a = CartItem(menuItem: burger, selectedModifiers: [bacon, cheese]);
      const b = CartItem(menuItem: burger, selectedModifiers: [cheese, bacon]);
      expect(a.configKey, b.configKey);
    });
  });

  group('CartTotals', () {
    test('empty cart totals are zero', () {
      final totals = CartTotals.fromItems(const []);
      expect(totals.subtotal, 0);
      expect(totals.taxAmount, 0);
      expect(totals.totalAmount, 0);
    });

    test('computes 15% tax and grand total', () {
      const item = CartItem(menuItem: burger, quantity: 2);
      final totals = CartTotals.fromItems(const [item]);
      expect(totals.subtotal, 56.0);
      expect(totals.taxAmount, closeTo(8.4, 0.001));
      expect(totals.totalAmount, closeTo(64.4, 0.001));
    });

    test('aggregates multiple items incl. modifiers', () {
      const a = CartItem(
        menuItem: burger,
        quantity: 2,
        selectedModifiers: [cheese],
      );
      const b = CartItem(menuItem: burger, quantity: 1);
      final totals = CartTotals.fromItems(const [a, b]);
      // a: (28+4)*2=64, b: 28 => subtotal 92
      expect(totals.subtotal, 92.0);
      expect(totals.taxAmount, closeTo(13.8, 0.001));
      expect(totals.totalAmount, closeTo(105.8, 0.001));
    });
  });
}
