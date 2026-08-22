import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/menu/presentation/controllers/menu_controller.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';

import 'test_container.dart';

void main() {
  const extraItem = MenuItem(
    id: 'x-item',
    categoryId: 'مشروبات',
    name: 'عصير ليمون',
    description: 'عصير ليمون طازج مثلج',
    price: 42,
  );

  test('extraCheckoutItems are served and pass checkout revalidation', () async {
    final container = createTestContainer(
      seedCheckoutFixtures: true,
      extraCheckoutItems: [extraItem],
    );
    addTearDown(container.dispose);

    await primeMenuForCheckout(container);

    // The extra item is reachable by id in the live menu snapshot, and its
    // new category was appended to the fixture category list.
    final menu = container.read(menuControllerProvider).valueOrNull;
    expect(menu, isNotNull);
    expect(
      menu!.items.any((item) => item.id == 'x-item' && item.price == 42),
      isTrue,
    );
    expect(menu.categories, contains('مشروبات'));

    container
        .read(cartControllerProvider.notifier)
        .addItem(const CartItem(menuItem: extraItem));

    final order = await container.read(ordersControllerProvider.notifier).placeOrder();

    expect(order, isNotNull);
    expect(order!.items.any((item) => item.menuItem.id == 'x-item'), isTrue);
  });

  test('extras alone imply fixture seeding (b1/f1 also served)', () async {
    final container = createTestContainer(extraCheckoutItems: [extraItem]);
    addTearDown(container.dispose);

    await primeMenuForCheckout(container);

    final menu = container.read(menuControllerProvider).valueOrNull;
    final ids = menu?.items.map((item) => item.id).toSet() ?? <String>{};
    expect(ids, containsAll(<String>['b1', 'f1', 'x-item']));
  });
}
