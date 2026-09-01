import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:restaurant_app/config/constants.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/cart/presentation/pages/cart_page.dart';
import 'package:restaurant_app/features/customer/presentation/pages/order_history_page.dart';
import 'package:restaurant_app/features/delivery/data/repositories/in_memory_delivery_repository.dart';
import 'package:restaurant_app/features/delivery/domain/entities/delivery_assignment.dart';
import 'package:restaurant_app/features/delivery/presentation/controllers/delivery_controller.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_entity.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';
import 'package:restaurant_app/features/ratings/domain/entities/rating_entity.dart';
import 'package:restaurant_app/features/ratings/presentation/controllers/rating_controller.dart';
import 'package:restaurant_app/features/ratings/presentation/widgets/rating_dialog.dart';
import '../../helpers/test_container.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar');
  });

  const burger = MenuItem(
    id: 'b1',
    categoryId: 'برجر',
    name: 'برجر كلاسيك',
    description: 'وصف',
    price: 28,
  );
  const fries = MenuItem(
    id: 'f1',
    categoryId: 'مقبلات',
    name: 'بطاطس مقلية',
    description: 'وصف',
    price: 12,
  );

  testWidgets('shows empty state when no orders', (tester) async {
    final container = createTestContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: OrderHistoryPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('لا توجد طلبات حالياً'), findsOneWidget);
  });

  testWidgets('lists placed orders with reorder action', (tester) async {
    final container = createTestContainer(seedCheckoutFixtures: true);
    addTearDown(container.dispose);
    await primeMenuForCheckout(container);

    final cart = container.read(cartControllerProvider.notifier);
    cart.addItem(const CartItem(menuItem: burger, quantity: 2));
    cart.addItem(const CartItem(menuItem: fries));
    await container
        .read(ordersControllerProvider.notifier)
        .placeOrder(paymentMethod: PaymentMethod.card);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: OrderHistoryPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('برجر كلاسيك'), findsOneWidget);
    expect(find.textContaining('بطاطس مقلية'), findsOneWidget);
    expect(find.text('أعد الطلب'), findsOneWidget);
    // Payment method shown on the history card.
    expect(find.textContaining('الدفع: بطاقة'), findsOneWidget);
  });

  testWidgets('reorder adds items back to the cart', (tester) async {
    final container = createTestContainer(seedCheckoutFixtures: true);
    addTearDown(container.dispose);
    await primeMenuForCheckout(container);

    final cart = container.read(cartControllerProvider.notifier);
    cart.addItem(const CartItem(menuItem: burger, quantity: 2));
    cart.addItem(const CartItem(menuItem: fries));
    await container.read(ordersControllerProvider.notifier).placeOrder();

    expect(cart.state, isEmpty); // cart cleared after ordering

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const OrderHistoryPage(),
        ),
        GoRoute(
          path: '/customer/cart',
          builder: (context, state) => const CartPage(),
        ),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('أعد الطلب'));
    await tester.pumpAndSettle();

    expect(cart.unitCount, 3); // 2 burgers + 1 fries
    expect(cart.state, hasLength(2));
    // Reorder navigates straight to the cart for review/checkout.
    expect(find.byType(CartPage), findsOneWidget);
  });

  testWidgets('reorder skips unavailable items', (tester) async {
    final container = createTestContainer(seedCheckoutFixtures: true);
    addTearDown(container.dispose);
    await primeMenuForCheckout(container);

    // fries becomes unavailable after the original order was placed.
    final cart = container.read(cartControllerProvider.notifier);
    cart.addItem(const CartItem(menuItem: fries));
    await container.read(ordersControllerProvider.notifier).placeOrder();
    final unavailableFries = fries.copyWith(isAvailable: false);

    final orders = container.read(ordersControllerProvider.notifier);
    final placed = orders.state.single;
    orders.state = [
      placed.copyWith(
        items: [placed.items.single.copyWith(menuItem: unavailableFries)],
      ),
    ];

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const OrderHistoryPage(),
        ),
        GoRoute(
          path: '/customer/cart',
          builder: (context, state) => const CartPage(),
        ),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('أعد الطلب'));
    await tester.pumpAndSettle();

    // No items were added because the only item is now unavailable.
    expect(cart.state, isEmpty);
    expect(find.text('لا يوجد أصناف لإعادة طلبها'), findsOneWidget);
  });

  testWidgets('reorder reports skipped items when some are unavailable', (
    tester,
  ) async {
    final container = createTestContainer(seedCheckoutFixtures: true);
    addTearDown(container.dispose);
    await primeMenuForCheckout(container);

    final cart = container.read(cartControllerProvider.notifier);
    cart.addItem(const CartItem(menuItem: burger));
    cart.addItem(const CartItem(menuItem: fries));
    await container.read(ordersControllerProvider.notifier).placeOrder();

    // Fries becomes unavailable; burger stays available.
    final orders = container.read(ordersControllerProvider.notifier);
    final placed = orders.state.single;
    final burgerItem = placed.items.firstWhere(
      (i) => i.menuItem.id == burger.id,
    );
    final friesItem = placed.items
        .firstWhere((i) => i.menuItem.id == fries.id)
        .copyWith(menuItem: fries.copyWith(isAvailable: false));
    orders.state = [
      placed.copyWith(items: [burgerItem, friesItem]),
    ];

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const OrderHistoryPage(),
        ),
        GoRoute(
          path: '/customer/cart',
          builder: (context, state) => const CartPage(),
        ),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('أعد الطلب'));
    await tester.pumpAndSettle();

    // Only the available burger is added; fries is reported as skipped.
    expect(cart.state, hasLength(1));
    expect(cart.state.first.menuItem.id, burger.id);
    expect(find.textContaining('تم تخطي'), findsOneWidget);
  });

  group('driver info on delivery orders (Gap 4 follow-up)', () {
    const driverId = 'driver-77';
    const driverName = 'كريم محمود';

    DeliveryAssignment buildAssignment({
      required String orderId,
      DeliveryStatus status = DeliveryStatus.inTransit,
    }) {
      return DeliveryAssignment(
        id: 'ASG-$orderId',
        orderId: orderId,
        driverId: driverId,
        pickupTime: DateTime.now(),
        deliveryLocation: 'حي النخيل، القاهرة',
        deliveryStatus: status,
        driverName: driverName,
        driverRating: 4.7,
      );
    }

    /// Places an order of [orderType], seeds its delivery assignment into an
    /// overridden [InMemoryDeliveryRepository] and pumps the history page.
    /// Pass [router] to pump inside a GoRouter-backed app (needed for
    /// navigation assertions).
    Future<ProviderContainer> pumpHistoryWithAssignment(
      WidgetTester tester, {
      required OrderType orderType,
      DeliveryStatus assignmentStatus = DeliveryStatus.inTransit,
      GoRouter? router,
    }) async {
      // Overriding the repository keeps the lookup local and lets the test
      // seed the assignment the card should render.
      final deliveryRepo = InMemoryDeliveryRepository(seed: const []);
      final container = createTestContainer(
        seedCheckoutFixtures: true,
        additionalOverrides: [
          deliveryRepositoryProvider.overrideWithValue(deliveryRepo),
        ],
      );
      addTearDown(container.dispose);
      await primeMenuForCheckout(container);

      container
          .read(cartControllerProvider.notifier)
          .addItem(const CartItem(menuItem: burger));
      final placed = await container
          .read(ordersControllerProvider.notifier)
          .placeOrder(orderType: orderType);
      // Seeded after placement: the assignment must reference the real id.
      await deliveryRepo.createAssignment(
        buildAssignment(orderId: placed!.id, status: assignmentStatus),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: router == null
              ? const MaterialApp(home: OrderHistoryPage())
              : MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('delivery card shows driver name and rating', (tester) async {
      await pumpHistoryWithAssignment(tester, orderType: OrderType.delivery);

      expect(find.text(driverName), findsOneWidget);
      expect(find.text('4.7'), findsOneWidget);
      // Still in transit → no rate-driver entry yet.
      expect(find.text('قيّم السائق'), findsNothing);
    });

    testWidgets('delivered assignment adds rate-driver entry opening the '
        'rating dialog', (tester) async {
      final container = await pumpHistoryWithAssignment(
        tester,
        orderType: OrderType.delivery,
        assignmentStatus: DeliveryStatus.delivered,
      );

      expect(find.text(driverName), findsOneWidget);
      expect(find.text('قيّم السائق'), findsOneWidget);

      await tester.tap(find.text('قيّم السائق'));
      await tester.pumpAndSettle();

      expect(find.byType(RatingDialog), findsOneWidget);
      expect(find.text('تقييم السائق'), findsOneWidget);

      // Submitting flows through the real ratings controller/repository.
      await tester.tap(find.text('إرسال التقييم'));
      await tester.pumpAndSettle();
      expect(find.byType(RatingDialog), findsNothing);

      final stored = await container.read(
        targetRatingsProvider(driverId).future,
      );
      expect(stored, hasLength(1));
      expect(stored.single.targetType, RatingTargetType.driver);
      expect(stored.single.targetId, driverId);
    });

    testWidgets('takeaway cards never render driver data even when an '
        'assignment exists', (tester) async {
      await pumpHistoryWithAssignment(tester, orderType: OrderType.takeaway);

      expect(find.text(driverName), findsNothing);
      expect(find.text('4.7'), findsNothing);
      expect(find.text('قيّم السائق'), findsNothing);
      // Card itself renders unchanged.
      expect(find.text('أعد الطلب'), findsOneWidget);
    });

    testWidgets('delivery card with assignment offers a driver-chat entry', (
      tester,
    ) async {
      await pumpHistoryWithAssignment(tester, orderType: OrderType.delivery);

      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
      expect(find.byTooltip('محادثة السائق'), findsOneWidget);
    });

    testWidgets('dine-in and takeaway cards show no driver-chat entry even '
        'when an assignment exists', (tester) async {
      for (final type in [OrderType.dineIn, OrderType.takeaway]) {
        await pumpHistoryWithAssignment(tester, orderType: type);

        expect(find.byIcon(Icons.chat_bubble_outline), findsNothing);
        expect(find.byTooltip('محادثة السائق'), findsNothing);
      }
    });

    testWidgets('tapping driver-chat navigates to /chat/:orderId', (
      tester,
    ) async {
      Object? navigatedTo;
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const OrderHistoryPage(),
          ),
          GoRoute(
            path: '/chat/:orderId',
            builder: (context, state) {
              navigatedTo = state.uri.path;
              return Scaffold(
                body: Center(
                  child: Text('chat-stub-${state.pathParameters['orderId']}'),
                ),
              );
            },
          ),
        ],
      );
      final container = await pumpHistoryWithAssignment(
        tester,
        orderType: OrderType.delivery,
        router: router,
      );
      final orderId = container.read(ordersControllerProvider).single.id;

      await tester.tap(find.byIcon(Icons.chat_bubble_outline));
      await tester.pumpAndSettle();

      expect(navigatedTo, '/chat/$orderId');
      expect(find.text('chat-stub-$orderId'), findsOneWidget);
    });
  });

  group('order history display window (Cycle 14)', () {
    /// Enlarges the test viewport so [ListView.builder] materializes every
    /// row of the bounded window — with the default 800×600 surface only
    /// the first few cards would be built, making count assertions useless.
    void useTallViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(1080, 24000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    /// Places [count] staggered takeaway orders into controller state
    /// (ids ORD-1001..ORD-1000+count, createdAt strictly increasing so
    /// ORD-1000+count is always the newest).
    ///
    /// Entities are built DIRECTLY instead of via placeOrder: the provider's
    /// real RealtimeService would loopback-broadcast orderCreated for a real
    /// placement, and that async echo lands AFTER the state replacement
    /// below — re-appending the original order and breaking exact counts.
    ProviderContainer seedOrders(WidgetTester tester, int count) {
      final container = createTestContainer(seedCheckoutFixtures: true);
      addTearDown(container.dispose);

      final base = DateTime(2026, 8, 24, 12);
      container.read(ordersControllerProvider.notifier).state = [
        for (var i = 1; i <= count; i++)
          OrderEntity(
            id: 'ORD-${1000 + i}',
            restaurantId: 'demo-restaurant-1',
            orderType: OrderType.takeaway,
            items: const [],
            status: OrderStatus.completed,
            subtotal: 10,
            taxAmount: 1.5,
            discountAmount: 0,
            totalAmount: 11.5,
            createdAt: base.add(Duration(minutes: i)),
          ),
      ];
      return container;
    }

    Future<void> pumpHistory(
      WidgetTester tester,
      ProviderContainer container,
    ) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: OrderHistoryPage()),
        ),
      );
      await tester.pumpAndSettle();
    }

    /// Each history card renders exactly one reorder button, so counting
    /// 'أعد الطلب' labels counts rendered cards.
    Finder reorderButtons() => find.text(AppConstants.reorderAction);

    testWidgets('initial render shows only the newest window, newest first', (
      tester,
    ) async {
      useTallViewport(tester);
      const total = AppConstants.orderHistoryInitialWindow + 5;
      final container = seedOrders(tester, total);
      await pumpHistory(tester, container);

      // Window bound respected: exactly the newest N orders render.
      expect(
        reorderButtons(),
        findsNWidgets(AppConstants.orderHistoryInitialWindow),
      );
      // More remain hidden behind the "عرض المزيد" row.
      expect(find.text(AppConstants.orderHistoryLoadMore), findsOneWidget);

      // Newest-first ordering: #1025 (newest) renders above #1024, and the
      // oldest orders stay outside the window entirely.
      String label(int i) => '#${1000 + i}';
      expect(
        tester.getTopLeft(find.textContaining(label(total))).dy,
        lessThan(tester.getTopLeft(find.textContaining(label(total - 1))).dy),
        reason: 'Newer orders must render above older ones',
      );
      expect(find.textContaining(label(total)), findsOneWidget);
      expect(find.textContaining(label(2)), findsNothing);
    });

    testWidgets('load more extends the window by one page', (tester) async {
      useTallViewport(tester);
      const total = AppConstants.orderHistoryInitialWindow + 5;
      final container = seedOrders(tester, total);
      await pumpHistory(tester, container);

      await tester.tap(find.text(AppConstants.orderHistoryLoadMore));
      await tester.pumpAndSettle();

      expect(reorderButtons(), findsNWidgets(total));
      // Exhausted: everything is visible and the button disappears.
      expect(find.text(AppConstants.orderHistoryLoadMore), findsNothing);
      expect(find.textContaining('#${1000 + 1}'), findsOneWidget);
    });

    testWidgets('no load-more button when the list fits the initial window', (
      tester,
    ) async {
      useTallViewport(tester);
      final container = seedOrders(
        tester,
        AppConstants.orderHistoryInitialWindow,
      );
      await pumpHistory(tester, container);

      expect(
        reorderButtons(),
        findsNWidgets(AppConstants.orderHistoryInitialWindow),
      );
      expect(find.text(AppConstants.orderHistoryLoadMore), findsNothing);
    });
  });
}
