import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/cart/domain/cart_totals.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';

void main() {
  const itemA = MenuItem(
    id: 'a',
    categoryId: 'c1',
    name: 'وجبة 1',
    description: 'وصف',
    price: 40.0,
  );

  const itemB = MenuItem(
    id: 'b',
    categoryId: 'c1',
    name: 'وجبة 2',
    description: 'وصف',
    price: 60.0,
  );

  const extraSauce = MenuModifierOption(
    id: 's1',
    name: 'صوص إضافي',
    extraPrice: 5.0,
  );

  group('CartTotals Unit Tests', () {
    test('empty items produces all zero values', () {
      final totals = CartTotals.fromItems(const []);
      expect(totals.subtotal, 0.0);
      expect(totals.discountAmount, 0.0);
      expect(totals.taxAmount, 0.0);
      expect(totals.totalAmount, 0.0);
    });

    test('single item without discount calculates 15% tax correctly', () {
      const cartItems = [
        CartItem(menuItem: itemA, quantity: 2), // 40 * 2 = 80
      ];

      final totals = CartTotals.fromItems(cartItems);
      expect(totals.subtotal, 80.0);
      expect(totals.discountAmount, 0.0);
      expect(totals.taxAmount, closeTo(12.0, 0.001)); // 80 * 0.15 = 12
      expect(totals.totalAmount, closeTo(92.0, 0.001)); // 80 + 12 = 92
    });

    test('items with modifiers calculate line prices correctly', () {
      const cartItems = [
        CartItem(
          menuItem: itemB, // 60
          quantity: 1,
          selectedModifiers: [extraSauce], // +5 = 65
        ),
      ];

      final totals = CartTotals.fromItems(cartItems);
      expect(totals.subtotal, 65.0);
      expect(totals.taxAmount, closeTo(9.75, 0.001)); // 65 * 0.15 = 9.75
      expect(totals.totalAmount, closeTo(74.75, 0.001));
    });

    test('applying discount reduces tax and total', () {
      const cartItems = [
        CartItem(menuItem: itemA, quantity: 1), // 40
        CartItem(menuItem: itemB, quantity: 1), // 60
      ]; // subtotal = 100

      final totals = CartTotals.fromItems(cartItems, discountAmount: 20.0);
      expect(totals.subtotal, 100.0);
      expect(totals.discountAmount, 20.0);
      // Effective subtotal = 80
      expect(totals.taxAmount, closeTo(12.0, 0.001)); // 80 * 0.15 = 12
      expect(totals.totalAmount, closeTo(92.0, 0.001)); // 80 + 12 = 92
    });

    test('discount greater than subtotal is clamped at zero', () {
      const cartItems = [
        CartItem(menuItem: itemA, quantity: 1), // 40
      ];

      final totals = CartTotals.fromItems(cartItems, discountAmount: 100.0);
      expect(totals.subtotal, 40.0);
      expect(totals.discountAmount, 100.0);
      expect(totals.taxAmount, 0.0);
      expect(totals.totalAmount, 0.0);
    });

    test('toString returns formatted string representation', () {
      final totals = CartTotals.fromItems(const []);
      expect(totals.toString().contains('CartTotals'), isTrue);
    });
  });
}
