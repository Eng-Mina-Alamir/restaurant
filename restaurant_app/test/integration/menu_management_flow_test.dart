import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/menu/presentation/controllers/menu_controller.dart';

void main() {
  group('Menu Management Flow Integration Test', () {
    test('adds custom menu item, filters menu, and verifies availability toggle', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final menuNotifier = container.read(menuControllerProvider.notifier);

      // Wait for initial menu load
      final initialMenu = await container.read(menuControllerProvider.future);
      expect(initialMenu.items, isNotEmpty);

      const newItem = MenuItem(
        id: 'item-custom-99',
        categoryId: 'grills',
        name: 'ريش ضأن فاخرة',
        description: 'ريش مشوية متبلة بالبهارات الخاصة',
        price: 180.0,
        isAvailable: true,
      );

      await menuNotifier.addItem(newItem);

      final updatedMenu = await container.read(menuControllerProvider.future);
      expect(updatedMenu.items.any((i) => i.id == 'item-custom-99'), isTrue);

      final filtered = filterMenu(updatedMenu, 'grills', 'ريش');
      expect(filtered, hasLength(1));
      expect(filtered.first.price, 180.0);

      // Toggle availability
      await menuNotifier.toggleAvailability('item-custom-99', false);
      final toggledMenu = await container.read(menuControllerProvider.future);
      final toggledItem = toggledMenu.items.firstWhere((i) => i.id == 'item-custom-99');
      expect(toggledItem.isAvailable, isFalse);
    });
  });
}
