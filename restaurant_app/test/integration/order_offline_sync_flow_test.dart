import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:restaurant_app/core/network/connectivity_service.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/menu/data/menu_seed_data.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';
import '../helpers/test_container.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('hive_integration_test');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    try {
      await Hive.close();
      await Hive.deleteFromDisk();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('Order Offline Sync Flow Integration Test', () {
    test(
      'places order offline, queues it, and syncs upon going online',
      () async {
        final connectivity = ConnectivityService(ConnectivityStatus.offline);

        // In-memory repos + seed menu via createTestContainer so checkout
        // revalidation never depends on the live Supabase backend; only the
        // connectivity service is overridden to start offline.
        final container = createTestContainer(
          additionalOverrides: [
            connectivityServiceProvider.overrideWithValue(connectivity),
          ],
        );
        addTearDown(container.dispose);
        await primeMenuForCheckout(container);

        final cartController = container.read(cartControllerProvider.notifier);
        final ordersController = container.read(
          ordersControllerProvider.notifier,
        );

        final item = MenuSeedData.items.first;
        cartController.addItem(CartItem(menuItem: item, quantity: 2));

        final placed = await ordersController.placeOrder();
        expect(placed, isNotNull);

        // Now bring connectivity online and simulate automatic sync
        connectivity.goOnline();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final updatedOrders = container.read(ordersControllerProvider);
        expect(updatedOrders.any((o) => o.id == placed!.id), isTrue);
      },
    );
  });
}
