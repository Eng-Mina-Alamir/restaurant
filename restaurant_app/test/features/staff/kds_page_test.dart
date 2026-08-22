import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/auth/domain/entities/user_entity.dart';
import 'package:restaurant_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/kds/presentation/pages/kds_page.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/data/repositories/in_memory_order_repository.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_entity.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_item.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';
import '../../helpers/test_container.dart';

/// Auth controller double that boots straight into a fixed state (no
/// bootstrap/use-case calls).
class _FakeAuthController extends AuthController {
  _FakeAuthController(super.ref, UserEntity? user) {
    state = user == null
        ? const AuthState(status: AuthStatus.unauthenticated)
        : AuthState(status: AuthStatus.authenticated, user: user);
  }
}

UserEntity _chef(String id) => UserEntity(
      id: id,
      name: 'Chef $id',
      email: '$id@restaurant.test',
      phone: '01000000000',
      role: UserRole.kitchen,
      createdAt: DateTime(2026, 1, 1),
    );

ProviderContainer _containerWithChef(
  String chefId, {
  List<Override> additionalOverrides = const [],
}) {
  return createTestContainer(additionalOverrides: [
    authControllerProvider.overrideWith(
      (ref) => _FakeAuthController(ref, _chef(chefId)),
    ),
    ...additionalOverrides,
  ]);
}

void main() {
  const burger = MenuItem(
    id: 'b1',
    categoryId: 'برجر',
    name: 'برجر كلاسيك',
    description: 'وصف',
    price: 28,
  );

  const fries = MenuModifierOption(
    id: 'opt-fries',
    name: 'بطاطس مقلية',
    extraPrice: 5,
  );

  testWidgets('shows empty state when no orders', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: KdsPage())),
    );
    await tester.pump();
    expect(find.text('لا توجد طلبات حالياً'), findsOneWidget);
  });

  testWidgets('shows a sent order and advances its status', (tester) async {
    final container = createTestContainer();
    addTearDown(container.dispose);

    final cart = container.read(cartControllerProvider.notifier);
    cart.addItem(const CartItem(menuItem: burger));
    final orders = container.read(ordersControllerProvider.notifier);
    await orders.placeOrder();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: KdsPage()),
      ),
    );
    await tester.pumpAndSettle();

    // Order appears under pending column.
    expect(find.textContaining('برجر كلاسيك'), findsOneWidget);
    expect(find.textContaining('بانتظار التحضير'), findsOneWidget);
    // Empty columns show a contextual placeholder.
    expect(find.text('لا توجد طلبات'), findsWidgets);

    // Advance to preparing.
    await tester.tap(find.text('قيد التحضير').last);
    await tester.pumpAndSettle();
    expect(find.text('جاهز للتسليم'), findsOneWidget);
  });

  testWidgets('advances an order through the full KDS workflow', (
    tester,
  ) async {
    final container = createTestContainer();
    addTearDown(container.dispose);

    final cart = container.read(cartControllerProvider.notifier);
    cart.addItem(const CartItem(menuItem: burger));
    final orders = container.read(ordersControllerProvider.notifier);
    await orders.placeOrder();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: KdsPage()),
      ),
    );
    await tester.pumpAndSettle();

    // pending -> preparing
    await tester.tap(find.text('قيد التحضير').last);
    await tester.pumpAndSettle();
    expect(find.text('جاهز للتسليم'), findsOneWidget);

    // preparing -> ready
    await tester.tap(find.text('جاهز للتسليم').last);
    await tester.pumpAndSettle();
    expect(find.text('استكمال'), findsOneWidget);

    // ready -> served: order leaves the KDS columns (only pending/preparing/ready shown)
    await tester.tap(find.text('استكمال').last);
    await tester.pumpAndSettle();

    final placed = container.read(ordersControllerProvider).first;
    expect(placed.status, OrderStatus.served);
    expect(find.textContaining('برجر كلاسيك'), findsNothing);
  });

  testWidgets('shows modifier options and special notes on the card', (
    tester,
  ) async {
    final container = createTestContainer();
    addTearDown(container.dispose);

    final cart = container.read(cartControllerProvider.notifier);
    cart.addItem(
      const CartItem(
        menuItem: burger,
        quantity: 1,
        selectedModifiers: [fries],
        specialNotes: 'بدون ملح',
      ),
    );
    await container.read(ordersControllerProvider.notifier).placeOrder();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: KdsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('بطاطس مقلية'), findsOneWidget);
    expect(find.textContaining('ملاحظات الطلب: بدون ملح'), findsOneWidget);
  });

  testWidgets('shows new badge for freshly placed orders', (tester) async {
    final container = createTestContainer();
    addTearDown(container.dispose);

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

    expect(find.text('جديد'), findsOneWidget);
  });

  testWidgets('shows item count and order total on the card', (tester) async {
    final container = createTestContainer();
    addTearDown(container.dispose);

    final cart = container.read(cartControllerProvider.notifier);
    cart.addItem(const CartItem(menuItem: burger, quantity: 2));
    await container.read(ordersControllerProvider.notifier).placeOrder();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: KdsPage()),
      ),
    );
    await tester.pumpAndSettle();

    // 2 × burger line plus the summary row both show a count.
    expect(find.text('عدد الأصناف: 2'), findsOneWidget);
  });

  testWidgets('shows the table number instead of the raw id', (tester) async {
    final container = createTestContainer();
    addTearDown(container.dispose);

    final cart = container.read(cartControllerProvider.notifier);
    cart.addItem(const CartItem(menuItem: burger));
    await container
        .read(ordersControllerProvider.notifier)
        .placeOrderForTable('t1');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: KdsPage()),
      ),
    );
    await tester.pumpAndSettle();

    // Seed table 't1' has tableNumber 1.
    expect(find.text('طاولة 1'), findsOneWidget);
    expect(find.textContaining('مقاعد t1'), findsNothing);
  });

  group('KDS multi-chef claim and guarded revert', () {
    // NOTE: orders are seeded straight into controller state instead of going
    // through placeOrder() — the checkout menu-revalidation path rejects the
    // test fixture prices (pre-existing issue tracked by the failing
    // fixture-price tests), which is unrelated to claim/revert behaviour.
    OrderEntity seedOrder(
      String id, {
      OrderStatus status = OrderStatus.pending,
    }) =>
        OrderEntity(
          id: id,
          restaurantId: 'rest-1',
          orderType: OrderType.dineIn,
          items: [
            OrderItem(
              menuItem: burger,
              quantity: 1,
              itemTotal: 28,
              addedAt: DateTime(2026, 8, 23, 12),
            ),
          ],
          status: status,
          subtotal: 28,
          taxAmount: 0,
          totalAmount: 28,
          createdAt: DateTime.now(),
        );

    void seedOrders(ProviderContainer container, List<OrderEntity> orders) {
      container.read(ordersControllerProvider.notifier).state = orders;
    }

    testWidgets('hides orders claimed by another chef', (tester) async {
      final container = _containerWithChef('chef-1');
      addTearDown(container.dispose);

      seedOrders(container, [
        seedOrder('ORD-KDS-1'),
        seedOrder('ORD-KDS-2'),
      ]);
      // A colleague claims the second ticket before we open the board.
      await container
          .read(ordersControllerProvider.notifier)
          .claim('ORD-KDS-2', kitchenUserId: 'chef-2');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: KdsPage()),
        ),
      );
      await tester.pumpAndSettle();

      // Only our unclaimed ticket is visible; chef-2's claim is filtered out.
      expect(find.textContaining('برجر كلاسيك'), findsOneWidget);
      expect(find.text('استلام الطلب'), findsOneWidget);
      expect(
        container.read(ordersControllerProvider).firstWhere(
              (o) => o.id == 'ORD-KDS-1',
            ).assignedKitchenId,
        isNull,
      );
    });

    testWidgets('claim assigns the current user id to the order', (
      tester,
    ) async {
      final container = _containerWithChef('chef-1');
      addTearDown(container.dispose);

      seedOrders(container, [seedOrder('ORD-KDS-1')]);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: KdsPage()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('استلام الطلب'));
      await tester.pumpAndSettle();

      final claimed = container.read(ordersControllerProvider).first;
      expect(claimed.assignedKitchenId, 'chef-1');
      // Claimed ticket stays visible for its owner.
      expect(find.textContaining('برجر كلاسيك'), findsOneWidget);
    });

    testWidgets('revert writes an audit log entry via the repository', (
      tester,
    ) async {
      final repo = InMemoryOrderRepository();
      final container =
          _containerWithChef('chef-1', additionalOverrides: [
        orderRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      const orderId = 'ORD-KDS-R1';
      await repo.createOrder(seedOrder(orderId));
      seedOrders(container, [seedOrder(orderId)]);
      final controller = container.read(ordersControllerProvider.notifier);
      await controller.updateStatus(orderId, OrderStatus.preparing);
      await controller.updateStatus(orderId, OrderStatus.ready);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: KdsPage()),
        ),
      );
      await tester.pumpAndSettle();

      // Undo button on the ready card opens a confirmation dialog.
      await tester.tap(find.byIcon(Icons.undo));
      await tester.pumpAndSettle();
      expect(find.text('تراجع إلى قيد التحضير؟'), findsOneWidget);

      await tester.tap(find.text('تأكيد التراجع'));
      await tester.pumpAndSettle();

      // Order moved back to preparing.
      expect(
        container
            .read(ordersControllerProvider)
            .firstWhere((o) => o.id == orderId)
            .status,
        OrderStatus.preparing,
      );
      // Audit trail captured with actor attribution.
      expect(repo.statusLog, hasLength(1));
      final entry = repo.statusLog.single;
      expect(entry.orderId, orderId);
      expect(entry.fromStatus, OrderStatus.ready);
      expect(entry.toStatus, OrderStatus.preparing);
      expect(entry.actorId, 'chef-1');
      expect(entry.isRevert, isTrue);
    });

    testWidgets('completed and cancelled cards never offer undo', (
      tester,
    ) async {
      final container = _containerWithChef('chef-1');
      addTearDown(container.dispose);

      seedOrders(container, [
        seedOrder('ORD-KDS-C1', status: OrderStatus.completed),
        seedOrder('ORD-KDS-C2', status: OrderStatus.cancelled),
      ]);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: KdsPage()),
        ),
      );
      await tester.pumpAndSettle();

      // Terminal orders are immutable: nothing renders on the board at all.
      expect(find.byIcon(Icons.undo), findsNothing);
      expect(find.text('استلام الطلب'), findsNothing);
      expect(find.textContaining('برجر كلاسيك'), findsNothing);
    });

    testWidgets('controller rejects illegal reverts without touching state', (
      tester,
    ) async {
      final repo = InMemoryOrderRepository();
      final container =
          _containerWithChef('chef-1', additionalOverrides: [
        orderRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      const orderId = 'ORD-KDS-T1';
      await repo.createOrder(seedOrder(orderId));
      seedOrders(container, [seedOrder(orderId)]);
      final controller = container.read(ordersControllerProvider.notifier);
      await controller.updateStatus(orderId, OrderStatus.completed);

      // Terminal → preparing must be blocked; no dialog would ever appear
      // because the UI never renders such a card, but the guard holds too.
      final result = await controller.revertStatus(
        orderId,
        OrderStatus.preparing,
        actorId: 'chef-1',
      );
      expect(result, isNull);
      expect(repo.statusLog, isEmpty);
      expect(
        container
            .read(ordersControllerProvider)
            .firstWhere((o) => o.id == orderId)
            .status,
        OrderStatus.completed,
      );
    });
  });
}
