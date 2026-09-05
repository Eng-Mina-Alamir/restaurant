import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/notifications/kds_alert_service.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/kds/presentation/pages/kds_page.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_entity.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_item.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';
import '../../helpers/spy_kds_alert_service.dart';
import '../../helpers/test_container.dart';

void main() {
  const burger = MenuItem(
    id: 'b1',
    categoryId: 'برجر',
    name: 'برجر كلاسيك',
    description: 'وصف',
    price: 28,
  );

  const pizza = MenuItem(
    id: 'p1',
    categoryId: 'بيتزا',
    name: 'بيتزا مارجريتا',
    description: 'بيتزا',
    price: 35,
  );

  const drink = MenuItem(
    id: 'd1',
    categoryId: 'مشروبات',
    name: 'عصير مانجو',
    description: 'عصير طازج',
    price: 15,
  );

  testWidgets('renders station chips and filters orders by station', (
    tester,
  ) async {
    final spy = SpyKdsAlertService();
    final container = createTestContainer(
      seedCheckoutFixtures: true,
      additionalOverrides: [kdsAlertServiceProvider.overrideWithValue(spy)],
    );
    addTearDown(container.dispose);

    final now = DateTime.now();
    final orderBurger = OrderEntity(
      id: 'ORD-GRILL-1',
      restaurantId: 'rest-1',
      orderType: OrderType.dineIn,
      items: [
        OrderItem(
          menuItem: burger,
          quantity: 1,
          itemTotal: 28,
          addedAt: now,
        ),
      ],
      status: OrderStatus.pending,
      subtotal: 28,
      taxAmount: 0,
      totalAmount: 28,
      createdAt: now,
    );

    final orderPizza = OrderEntity(
      id: 'ORD-BAKERY-1',
      restaurantId: 'rest-1',
      orderType: OrderType.takeaway,
      items: [
        OrderItem(
          menuItem: pizza,
          quantity: 1,
          itemTotal: 35,
          addedAt: now,
        ),
      ],
      status: OrderStatus.pending,
      subtotal: 35,
      taxAmount: 0,
      totalAmount: 35,
      createdAt: now,
    );

    container.read(ordersControllerProvider.notifier).state = [
      orderBurger,
      orderPizza,
    ];

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: KdsPage()),
      ),
    );
    await tester.pumpAndSettle();

    // Initial station is All: both burger and pizza appear.
    expect(find.textContaining('برجر كلاسيك'), findsOneWidget);
    expect(find.textContaining('بيتزا مارجريتا'), findsOneWidget);

    // Verify all 5 station chips exist
    expect(find.text('الكل'), findsWidgets);
    expect(find.text('الشواية واللحوم'), findsOneWidget);
    expect(find.text('الفرن والمخبوزات'), findsOneWidget);
    expect(find.text('المشروبات والبار'), findsOneWidget);
    expect(find.text('شاشة التجميع (Expo)'), findsOneWidget);

    // Tap Bakery station chip -> only pizza is visible
    await tester.tap(find.text('الفرن والمخبوزات'));
    await tester.pumpAndSettle();

    expect(find.textContaining('بيتزا مارجريتا'), findsOneWidget);
    expect(find.textContaining('برجر كلاسيك'), findsNothing);

    // Tap Grill station chip -> only burger is visible
    await tester.tap(find.text('الشواية واللحوم'));
    await tester.pumpAndSettle();

    expect(find.textContaining('برجر كلاسيك'), findsOneWidget);
    expect(find.textContaining('بيتزا مارجريتا'), findsNothing);
  });

  testWidgets('toggles alert sound mute state via AppBar action', (
    tester,
  ) async {
    final alertService = KdsAlertService();
    final container = createTestContainer(
      additionalOverrides: [
        kdsAlertServiceProvider.overrideWithValue(alertService),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: KdsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(alertService.isMuted, isFalse);

    // Tap sound toggle in AppBar
    await tester.tap(find.byIcon(Icons.volume_up_rounded));
    await tester.pumpAndSettle();

    expect(alertService.isMuted, isTrue);
    expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);

    // Tap again to unmute
    await tester.tap(find.byIcon(Icons.volume_off_rounded));
    await tester.pumpAndSettle();

    expect(alertService.isMuted, isFalse);
    expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
  });

  testWidgets('main CTA button satisfies touch target size >= 56px', (
    tester,
  ) async {
    final spy = SpyKdsAlertService();
    final container = createTestContainer(
      seedCheckoutFixtures: true,
      additionalOverrides: [kdsAlertServiceProvider.overrideWithValue(spy)],
    );
    addTearDown(container.dispose);
    await primeMenuForCheckout(container);

    final cart = container.read(cartControllerProvider.notifier);
    cart.addItem(const CartItem(menuItem: burger));
    await container.read(ordersControllerProvider.notifier).placeOrder();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: KdsPage()),
      ),
    );
    await tester.pumpAndSettle();

    // Locate the advance CTA button
    final ctaFinder = find.byKey(const ValueKey<String>('kds_action_preparing'));
    expect(ctaFinder, findsOneWidget);

    final RenderBox renderBox = tester.renderObject(ctaFinder);
    expect(renderBox.size.height, greaterThanOrEqualTo(56.0));
  });

  testWidgets('filters orders using the search bar by order id', (
    tester,
  ) async {
    final spy = SpyKdsAlertService();
    final container = createTestContainer(
      seedCheckoutFixtures: true,
      additionalOverrides: [kdsAlertServiceProvider.overrideWithValue(spy)],
    );
    addTearDown(container.dispose);

    final now = DateTime.now();
    final order1 = OrderEntity(
      id: 'ORD-ALPHA-100',
      restaurantId: 'rest-1',
      orderType: OrderType.dineIn,
      items: [
        OrderItem(menuItem: burger, quantity: 1, itemTotal: 28, addedAt: now),
      ],
      status: OrderStatus.pending,
      subtotal: 28,
      taxAmount: 0,
      totalAmount: 28,
      createdAt: now,
    );

    final order2 = OrderEntity(
      id: 'ORD-BETA-200',
      restaurantId: 'rest-1',
      orderType: OrderType.takeaway,
      items: [
        OrderItem(menuItem: drink, quantity: 1, itemTotal: 15, addedAt: now),
      ],
      status: OrderStatus.pending,
      subtotal: 15,
      taxAmount: 0,
      totalAmount: 15,
      createdAt: now,
    );

    container.read(ordersControllerProvider.notifier).state = [order1, order2];

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: KdsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('برجر كلاسيك'), findsOneWidget);
    expect(find.textContaining('عصير مانجو'), findsOneWidget);

    // Open search bar
    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pumpAndSettle();

    // Enter search query for order 100
    await tester.enterText(find.byType(TextField), '100');
    await tester.pumpAndSettle();

    expect(find.textContaining('برجر كلاسيك'), findsOneWidget);
    expect(find.textContaining('عصير مانجو'), findsNothing);
  });

  testWidgets('served orders do not leak into active KDS counts', (
    tester,
  ) async {
    final spy = SpyKdsAlertService();
    final container = createTestContainer(
      seedCheckoutFixtures: true,
      additionalOverrides: [kdsAlertServiceProvider.overrideWithValue(spy)],
    );
    addTearDown(container.dispose);

    final now = DateTime.now();
    // 3 served orders that previously leaked into active tickets
    final servedOrders = [
      OrderEntity(
        id: 'ORD-SERVED-1',
        restaurantId: 'rest-1',
        orderType: OrderType.dineIn,
        items: [
          OrderItem(menuItem: burger, quantity: 1, itemTotal: 28, addedAt: now),
        ],
        status: OrderStatus.served,
        subtotal: 28,
        taxAmount: 0,
        totalAmount: 28,
        createdAt: now.subtract(const Duration(minutes: 15)),
      ),
      OrderEntity(
        id: 'ORD-SERVED-2',
        restaurantId: 'rest-1',
        orderType: OrderType.dineIn,
        items: [
          OrderItem(menuItem: pizza, quantity: 1, itemTotal: 35, addedAt: now),
        ],
        status: OrderStatus.served,
        subtotal: 35,
        taxAmount: 0,
        totalAmount: 35,
        createdAt: now.subtract(const Duration(minutes: 20)),
      ),
    ];

    container.read(ordersControllerProvider.notifier).state = servedOrders;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: KdsPage()),
      ),
    );
    await tester.pumpAndSettle();

    // The whole kitchen board is calm because served orders are done
    expect(find.text('المطبخ هادئ الآن'), findsOneWidget);
    // Station chip 'الكل' shows count 0
    expect(find.text('0'), findsWidgets);
    // No delayed alert banner is shown
    expect(find.textContaining('تأخير في التحضير'), findsNothing);
  });

  testWidgets('mobile AppBar uses popup menu without overflow on narrow screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final spy = SpyKdsAlertService();
    final container = createTestContainer(
      seedCheckoutFixtures: true,
      additionalOverrides: [kdsAlertServiceProvider.overrideWithValue(spy)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: KdsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    // Search and sound toggle remain 1-tap accessible
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);

    // Overflow menu exists on mobile
    expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);

    // Tap overflow menu to verify options
    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.history_rounded), findsWidgets);
    expect(find.byIcon(Icons.logout), findsOneWidget);
  });
}

