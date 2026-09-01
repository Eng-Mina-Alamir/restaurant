import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cashier/domain/services/held_order_service.dart';
import 'package:restaurant_app/features/cashier/presentation/controllers/held_orders_controller.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';

void main() {
  const dummyBurger = MenuItem(
    id: 'item-1',
    name: 'برجر كلاسيك',
    description: 'برجر لحم بقري كلاسيك',
    price: 150.0,
    categoryId: 'burgers',
  );

  const dummyPizza = MenuItem(
    id: 'item-2',
    name: 'بيتزا مارجريتا',
    description: 'بيتزا مارجريتا إيطالية',
    price: 200.0,
    categoryId: 'pizza',
  );

  group('HeldOrderService & Controller', () {
    test('createHeldOrder creates valid held entity with items and calculations', () {
      final items = [
        const CartItem(menuItem: dummyBurger, quantity: 2), // 300
        const CartItem(menuItem: dummyPizza, quantity: 1), // 200
      ];

      final held = HeldOrderService.createHeldOrder(
        cartItems: items,
        customLabel: 'زبون تيك أواي مستعجل',
      );

      expect(held.label, equals('زبون تيك أواي مستعجل'));
      expect(held.items.length, equals(2));
      expect(held.totalAmount, equals(500.0));
      expect(held.totalItemsCount, equals(3));
    });

    test('HeldOrdersController parks, recalls, and discards orders properly', () {
      final controller = HeldOrdersController();

      final items = [
        const CartItem(menuItem: dummyBurger, quantity: 1),
      ];

      // Park order
      final held = controller.holdOrder(
        cartItems: items,
        customLabel: 'طاولة #5',
      );

      expect(held, isNotNull);
      expect(controller.heldCount, equals(1));
      expect(controller.state.first.label, equals('طاولة #5'));

      // Recall order
      final recalled = controller.recallOrder(held!.id);
      expect(recalled, isNotNull);
      expect(recalled!.id, equals(held.id));
      expect(controller.heldCount, equals(0));

      // Park and discard
      final held2 = controller.holdOrder(cartItems: items);
      expect(controller.heldCount, equals(1));
      controller.discardHeldOrder(held2!.id);
      expect(controller.heldCount, equals(0));
    });
  });
}
