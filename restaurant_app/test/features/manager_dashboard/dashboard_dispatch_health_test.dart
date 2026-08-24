import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:restaurant_app/config/constants.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/network/realtime_service.dart';
import 'package:restaurant_app/features/delivery/data/repositories/in_memory_delivery_repository.dart';
import 'package:restaurant_app/features/delivery/domain/entities/delivery_assignment.dart';
import 'package:restaurant_app/features/delivery/presentation/controllers/delivery_controller.dart';
import 'package:restaurant_app/features/manager_dashboard/presentation/controllers/dispatch_controller.dart';
import 'package:restaurant_app/features/manager_dashboard/presentation/pages/manager_dashboard_page.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_entity.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';

import '../../helpers/test_container.dart';

/// Read-only orders source so [dispatchControllerProvider] observes fixtures.
class OrdersControllerMock extends StateNotifier<List<OrderEntity>>
    implements OrdersController {
  OrdersControllerMock(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Controller whose initial [AsyncValue.loading] never resolves, so the
/// dashboard's dispatch-health card keeps rendering its loading shell.
class _StalledDispatchController extends DispatchController {
  _StalledDispatchController()
    : super(InMemoryDeliveryRepository(), RealtimeService(),
        ordersSource: () => const []);

  @override
  Future<void> refresh() async {}
}

OrderEntity buildOrder({required String id}) => OrderEntity(
  id: id,
  restaurantId: 'rest-1',
  orderType: OrderType.delivery,
  status: OrderStatus.ready,
  deliveryAddress: 'القاهرة - مدينة نصر',
  createdAt: DateTime.now(),
);

DeliveryAssignment buildAssignment({
  required String id,
  required String orderId,
  required String driverId,
  DeliveryStatus deliveryStatus = DeliveryStatus.inTransit,
}) => DeliveryAssignment(
  id: id,
  orderId: orderId,
  driverId: driverId,
  pickupTime: DateTime.now(),
  deliveryLocation: 'القاهرة - مدينة نصر',
  deliveryStatus: deliveryStatus,
  assignmentMethod: 'auto',
  assignedAt: DateTime.now(),
);

// Explicitly <String>: the page's inline `ValueKey('dispatch_health_card')`
// infers ValueKey<String>, and ValueKey equality compares runtime types — a
// bare `ValueKey` annotation would be ValueKey<dynamic> and never match.
const ValueKey<String> _healthCardKey = ValueKey<String>(
  'dispatch_health_card',
);

Finder _insideCard(Finder matcher) =>
    find.descendant(of: find.byKey(_healthCardKey), matching: matcher);

Future<void> pumpDashboard(
  WidgetTester tester,
  ProviderContainer container,
) async {
  final router = GoRouter(
    initialLocation: '/manager',
    routes: [
      GoRoute(
        path: '/manager',
        builder: (context, state) => const ManagerDashboardPage(),
      ),
      GoRoute(
        path: '/manager/dispatch',
        builder: (context, state) =>
            const Scaffold(body: Text('DISPATCH_BOARD_STUB')),
      ),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
}

void main() {
  testWidgets('seeded container renders the three dispatch-health counts', (
    tester,
  ) async {
    final container = createTestContainer(
      additionalOverrides: [
        deliveryRepositoryProvider.overrideWithValue(
          InMemoryDeliveryRepository(
            seed: [
              // Two busy drivers → سواق متاحون = 2.
              buildAssignment(
                id: 'ASG-run-1',
                orderId: 'ORD-OTHER-1',
                driverId: 'drv-1',
              ),
              buildAssignment(
                id: 'ASG-run-2',
                orderId: 'ORD-OTHER-2',
                driverId: 'drv-2',
              ),
              // One failed assignment awaiting re-dispatch → تكليفات فاشلة = 1.
              buildAssignment(
                id: 'ASG-fail-1',
                orderId: 'ORD-F',
                driverId: 'drv-dead',
                deliveryStatus: DeliveryStatus.failed,
              ),
            ],
          ),
        ),
        ordersControllerProvider.overrideWith(
          (ref) => OrdersControllerMock([
            buildOrder(id: 'ORD-A'),
            buildOrder(id: 'ORD-B'),
            buildOrder(id: 'ORD-C'),
            buildOrder(id: 'ORD-F'),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);

    await pumpDashboard(tester, container);
    await tester.pumpAndSettle();

    expect(find.byKey(_healthCardKey), findsOneWidget);
    // Three undispatched orders.
    expect(_insideCard(find.text('3')), findsOneWidget);
    expect(
      _insideCard(find.text(AppConstants.dispatchHealthPendingOrders)),
      findsOneWidget,
    );
    // One failed assignment.
    expect(_insideCard(find.text('1')), findsOneWidget);
    expect(
      _insideCard(find.text(AppConstants.dispatchHealthFailedAssignments)),
      findsOneWidget,
    );
    // Two available drivers.
    expect(_insideCard(find.text('2')), findsOneWidget);
    expect(
      _insideCard(find.text(AppConstants.dispatchHealthAvailableDrivers)),
      findsOneWidget,
    );
  });

  testWidgets('tapping the card opens the dispatch board', (tester) async {
    final container = createTestContainer(
      additionalOverrides: [
        deliveryRepositoryProvider.overrideWithValue(
          InMemoryDeliveryRepository(seed: const []),
        ),
        ordersControllerProvider.overrideWith(
          (ref) => OrdersControllerMock(const []),
        ),
      ],
    );
    addTearDown(container.dispose);

    await pumpDashboard(tester, container);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(_healthCardKey));
    await tester.tap(find.byKey(_healthCardKey));
    await tester.pumpAndSettle();

    expect(find.text('DISPATCH_BOARD_STUB'), findsOneWidget);
  });

  testWidgets('renders a loading shell while the board is AsyncLoading', (
    tester,
  ) async {
    final container = createTestContainer(
      additionalOverrides: [
        dispatchControllerProvider.overrideWith(
          (ref) => _StalledDispatchController(),
        ),
        ordersControllerProvider.overrideWith(
          (ref) => OrdersControllerMock(const []),
        ),
      ],
    );
    addTearDown(container.dispose);

    await pumpDashboard(tester, container);
    // Fixed pumps instead of pumpAndSettle: the loading shell hosts an
    // indeterminate spinner that never settles.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(_healthCardKey), findsOneWidget);
    expect(_insideCard(find.byType(CircularProgressIndicator)), findsOneWidget);
    expect(
      _insideCard(find.text(AppConstants.dispatchHealthLoading)),
      findsOneWidget,
    );
    // No count row while still loading.
    expect(
      _insideCard(find.text(AppConstants.dispatchHealthPendingOrders)),
      findsNothing,
    );
  });
}
