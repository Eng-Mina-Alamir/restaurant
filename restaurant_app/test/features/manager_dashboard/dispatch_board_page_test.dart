import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/delivery/data/repositories/in_memory_delivery_repository.dart';
import 'package:restaurant_app/features/delivery/domain/entities/delivery_assignment.dart';
import 'package:restaurant_app/features/delivery/presentation/controllers/delivery_controller.dart';
import 'package:restaurant_app/features/manager_dashboard/presentation/controllers/dispatch_controller.dart';
import 'package:restaurant_app/features/manager_dashboard/presentation/pages/dispatch_board_page.dart';
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

OrderEntity buildOrder({required String id}) => OrderEntity(
  id: id,
  restaurantId: 'rest-1',
  orderType: OrderType.delivery,
  status: OrderStatus.ready,
  deliveryAddress: 'القاهرة - مدينة نصر',
  createdAt: DateTime.now(),
);

DeliveryAssignment buildActiveDriverAssignment({
  required String orderId,
  required String driverId,
}) => DeliveryAssignment(
  id: 'ASG-$orderId-seed',
  orderId: orderId,
  driverId: driverId,
  pickupTime: DateTime.now(),
  deliveryLocation: 'القاهرة - مدينة نصر',
  deliveryStatus: DeliveryStatus.inTransit,
  assignmentMethod: 'auto',
  assignedAt: DateTime.now(),
);

Future<ProviderContainer> pumpBoard(
  WidgetTester tester, {
  required List<OrderEntity> orders,
  required InMemoryDeliveryRepository repository,
}) async {
  final container = createTestContainer(
    additionalOverrides: [
      deliveryRepositoryProvider.overrideWithValue(repository),
      ordersControllerProvider.overrideWith(
        (ref) => OrdersControllerMock(orders),
      ),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: DispatchBoardPage()),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('renders undispatched order card with address and status', (
    tester,
  ) async {
    await pumpBoard(
      tester,
      orders: [buildOrder(id: 'ORD-A')],
      repository: InMemoryDeliveryRepository(
        seed: [
          // An unrelated in-transit run makes its driver "available".
          buildActiveDriverAssignment(orderId: 'ORD-OTHER', driverId: 'drv-1'),
        ],
      ),
    );

    expect(find.text('طلبات بانتظار سواق'), findsOneWidget);
    expect(find.textContaining('ORD-A'), findsWidgets);
    expect(find.text('القاهرة - مدينة نصر'), findsOneWidget);
    expect(find.text(OrderStatus.ready.labelAr), findsOneWidget);
    expect(find.text('تعيين سواق'), findsOneWidget);
  });

  testWidgets('assign flow creates a manual-method assignment in the repo', (
    tester,
  ) async {
    final repo = InMemoryDeliveryRepository(
      seed: [
        buildActiveDriverAssignment(orderId: 'ORD-OTHER', driverId: 'drv-1'),
      ],
    );
    await pumpBoard(
      tester,
      orders: [buildOrder(id: 'ORD-A')],
      repository: repo,
    );

    await tester.tap(find.text('تعيين سواق'));
    await tester.pumpAndSettle();

    // The bottom sheet lists the available driver.
    expect(find.text('اختر سائقاً'), findsOneWidget);
    await tester.tap(find.text('drv-1').first);
    await tester.pumpAndSettle();

    expect(find.text('تم تعيين السائق بنجاح'), findsOneWidget);

    final created = (await repo.getAssignmentByOrderId(
      'ORD-A',
    )).when(onLeft: (f) => fail('lookup should not fail'), onRight: (a) => a);
    expect(created, isNotNull);
    expect(created!.assignmentMethod, 'manual');
    expect(created.driverId, 'drv-1');
    expect(created.deliveryStatus, DeliveryStatus.pending);
  });

  testWidgets('shows empty state when there is nothing to dispatch', (
    tester,
  ) async {
    await pumpBoard(
      tester,
      orders: const [],
      repository: InMemoryDeliveryRepository(seed: const []),
    );

    expect(find.text('لا توجد طلبات بانتظار سواق'), findsOneWidget);
    expect(find.text('لا توجد تكليفات فاشلة'), findsOneWidget);
    expect(find.text('تعيين سواق'), findsNothing);
  });

  testWidgets('shows failed section for failed assignments', (tester) async {
    final failedSeed = DeliveryAssignment(
      id: 'ASG-fail-1',
      orderId: 'ORD-F',
      driverId: 'drv-dead',
      pickupTime: DateTime.now(),
      deliveryLocation: 'الجيزة',
      deliveryStatus: DeliveryStatus.failed,
      assignmentMethod: 'auto',
      assignedAt: DateTime.now(),
    );
    await pumpBoard(
      tester,
      orders: [buildOrder(id: 'ORD-F')],
      repository: InMemoryDeliveryRepository(seed: [failedSeed]),
    );

    expect(find.text('إعادة تعيين (فشل سابق)'), findsOneWidget);
    expect(find.textContaining('فشل التكليف السابق'), findsOneWidget);
  });
}
