import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';

void main() {
  group('CartController Unit Tests', () {
    late CartController controller;

    const availableItem = MenuItem(
      id: 'i-1',
      categoryId: 'cat-1',
      name: 'كشري مصري',
      description: 'كشري بالدقة والصلصة',
      price: 30.0,
      isAvailable: true,
    );

    const unavailableItem = MenuItem(
      id: 'i-2',
      categoryId: 'cat-1',
      name: 'حمام محشي',
      description: 'غير متوفر حالياً',
      price: 90.0,
      isAvailable: false,
    );

    const emptyIdItem = MenuItem(
      id: '',
      categoryId: 'cat-1',
      name: 'صنف بدون معرف',
      description: '',
      price: 10.0,
      isAvailable: true,
    );

    setUp(() {
      controller = CartController();
    });

    test('initial state is empty', () {
      expect(controller.state, isEmpty);
      expect(controller.itemCount, 0);
      expect(controller.unitCount, 0);
      expect(controller.activeTableId, isNull);
    });

    test('addItem adds new available item', () {
      controller.addItem(const CartItem(menuItem: availableItem, quantity: 2));

      expect(controller.itemCount, 1);
      expect(controller.unitCount, 2);
      expect(controller.state.first.menuItem.id, 'i-1');
    });

    test('addItem merges with existing item with same configKey', () {
      controller.addItem(const CartItem(menuItem: availableItem, quantity: 1));
      controller.addItem(const CartItem(menuItem: availableItem, quantity: 3));

      expect(controller.itemCount, 1);
      expect(controller.unitCount, 4);
      expect(controller.state.first.quantity, 4);
    });

    test('addItem ignores unavailable, zero quantity or empty id items', () {
      controller.addItem(
        const CartItem(menuItem: unavailableItem, quantity: 1),
      );
      expect(controller.itemCount, 0);

      controller.addItem(const CartItem(menuItem: availableItem, quantity: 0));
      expect(controller.itemCount, 0);

      controller.addItem(const CartItem(menuItem: emptyIdItem, quantity: 1));
      expect(controller.itemCount, 0);
    });

    test('increment increases quantity for configKey', () {
      const item = CartItem(menuItem: availableItem, quantity: 1);
      controller.addItem(item);

      controller.increment(item.configKey);
      expect(controller.state.first.quantity, 2);
    });

    test('decrement decreases quantity and removes when reaching zero', () {
      const item = CartItem(menuItem: availableItem, quantity: 2);
      controller.addItem(item);

      controller.decrement(item.configKey);
      expect(controller.state.first.quantity, 1);

      controller.decrement(item.configKey);
      expect(controller.state, isEmpty);
    });

    test('removeItem removes matching line item', () {
      const item = CartItem(menuItem: availableItem, quantity: 5);
      controller.addItem(item);

      controller.removeItem(item.configKey);
      expect(controller.state, isEmpty);
    });

    test('clear empties cart and resets tableId', () {
      controller.setTableId('tbl-4');
      controller.addItem(const CartItem(menuItem: availableItem, quantity: 2));

      expect(controller.activeTableId, 'tbl-4');
      expect(controller.itemCount, 1);

      controller.clear();
      expect(controller.state, isEmpty);
      expect(controller.activeTableId, isNull);
    });

    test('splitTotal splits total evenly or returns total if persons <= 0', () {
      // 2 * 30 = 60 subtotal + 15% tax (9) = 69.0 total
      controller.addItem(const CartItem(menuItem: availableItem, quantity: 2));

      expect(controller.totals.totalAmount, 69.0);
      expect(controller.splitTotal(3), closeTo(23.0, 0.001));
      expect(controller.splitTotal(0), 69.0);
      expect(controller.splitTotal(-1), 69.0);
    });

    test('setTableId and clearTableId manage active table link', () {
      controller.setTableId('tbl-10');
      expect(controller.activeTableId, 'tbl-10');

      controller.clearTableId();
      expect(controller.activeTableId, isNull);
    });
  });
}
