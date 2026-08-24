import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/network/realtime_service.dart';
import 'package:restaurant_app/features/customer/presentation/pages/order_tracking_page.dart';
import 'package:restaurant_app/features/delivery/data/repositories/in_memory_delivery_repository.dart';
import 'package:restaurant_app/features/delivery/domain/entities/delivery_assignment.dart';
import 'package:restaurant_app/features/delivery/presentation/controllers/delivery_controller.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_entity.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_item.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';

import '../../helpers/test_http_overrides.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = TestHttpOverrides();
  });

  const burger = MenuItem(
    id: 'item-1',
    categoryId: 'cat-grill',
    name: 'كباب مشوي عالفحم',
    description: 'طازج ولذيذ',
    price: 95.0,
  );

  OrderEntity buildOrder({OrderStatus status = OrderStatus.preparing}) {
    return OrderEntity(
      id: 'ORD-TRK-1',
      restaurantId: 'rest-1',
      tableId: null,
      customerId: 'CUST-1',
      orderType: OrderType.delivery,
      status: status,
      items: [
        OrderItem(
          menuItem: burger,
          quantity: 2,
          selectedModifiers: const [],
          addedAt: DateTime.now(),
        ),
      ],
      subtotal: 190.0,
      taxAmount: 28.5,
      totalAmount: 218.5,
      createdAt: DateTime.now(),
    );
  }

  DeliveryAssignment buildAssignment({
    String orderId = 'ORD-TRK-1',
    String driverId = 'driver-x',
    String? driverName,
    String? driverPhone,
    double? driverRating,
    String? vehicleInfo,
  }) {
    return DeliveryAssignment(
      id: 'ASG-$orderId',
      orderId: orderId,
      driverId: driverId,
      pickupTime: DateTime.now(),
      deliveryLocation: 'المعادي، القاهرة',
      deliveryStatus: DeliveryStatus.inTransit,
      latitude: 30.02,
      longitude: 31.23,
      driverName: driverName,
      driverPhone: driverPhone,
      driverRating: driverRating,
      vehicleInfo: vehicleInfo,
    );
  }

  Future<void> pumpPage(
    WidgetTester tester, {
    required List<OrderEntity> orders,
    OrdersController? controller,
    // Defaults to an EMPTY assignment store so tests never touch remote
    // repositories; pass a seeded one when driver data matters.
    InMemoryDeliveryRepository? deliveryRepo,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ordersControllerProvider.overrideWith(
            (ref) => controller ?? OrdersControllerMock(orders),
          ),
          deliveryRepositoryProvider.overrideWithValue(
            deliveryRepo ?? InMemoryDeliveryRepository(seed: const []),
          ),
        ],
        child: MaterialApp(
          routes: {
            '/': (context) => const Scaffold(body: SizedBox.shrink()),
            '/tracking': (context) =>
                const OrderTrackingPage(orderId: 'ORD-TRK-1'),
          },
          initialRoute: '/tracking',
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('Cancel button visibility (pending-only rule)', () {
    testWidgets('visible while order is pending', (tester) async {
      await pumpPage(tester, orders: [buildOrder(status: OrderStatus.pending)]);

      expect(find.text('إلغاء الطلب'), findsOneWidget);
    });

    testWidgets('hidden once preparation started', (tester) async {
      await pumpPage(
        tester,
        orders: [buildOrder(status: OrderStatus.preparing)],
      );

      expect(find.text('إلغاء الطلب'), findsNothing);
    });

    testWidgets('hidden for completed orders', (tester) async {
      await pumpPage(
        tester,
        orders: [buildOrder(status: OrderStatus.completed)],
      );

      expect(find.text('إلغاء الطلب'), findsNothing);
    });
  });

  group('Cancellation flow', () {
    testWidgets('dialog confirms then cancels via controller and pops', (
      tester,
    ) async {
      final fakeController = FakeOrdersController([
        buildOrder(status: OrderStatus.pending),
      ]);
      await pumpPage(tester, orders: [], controller: fakeController);

      // The cancel button sits below the fold in the scrollable summary.
      await tester.ensureVisible(find.text('إلغاء الطلب'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إلغاء الطلب'));
      await tester.pumpAndSettle();

      // Confirmation dialog copy.
      expect(find.text('إلغاء الطلب'), findsNWidgets(2)); // button + title
      expect(
        find.text(
          'هل أنت متأكد من إلغاء الطلب؟ لا يمكن التراجع بعد بدء التحضير',
        ),
        findsOneWidget,
      );
      expect(find.text('نعم، إلغاء'), findsOneWidget);
      expect(find.text('رجوع'), findsOneWidget);

      // Dismiss path keeps the order intact.
      await tester.tap(find.text('رجوع'));
      await tester.pumpAndSettle();
      expect(fakeController.cancelledOrderIds, isEmpty);

      // Confirm path cancels the order.
      await tester.ensureVisible(find.text('إلغاء الطلب'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إلغاء الطلب'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('نعم، إلغاء'));
      await tester.pumpAndSettle();

      expect(fakeController.cancelledOrderIds, ['ORD-TRK-1']);
      expect(find.text('تم إلغاء الطلب بنجاح'), findsOneWidget);
      // Page popped back to the root route after successful cancellation.
      expect(find.byType(OrderTrackingPage), findsNothing);
    });
  });

  group('Driver section', () {
    testWidgets('shows search placeholder when no assignment exists', (
      tester,
    ) async {
      await pumpPage(
        tester,
        orders: [buildOrder()],
        deliveryRepo: InMemoryDeliveryRepository(seed: const []),
      );

      expect(find.textContaining('جارٍ البحث عن مندوب'), findsOneWidget);
      // No fabricated driver personalities.
      expect(find.textContaining('طارق'), findsNothing);
      expect(find.textContaining('01066778899'), findsNothing);
    });

    testWidgets('renders live driver data from the fetched assignment', (
      tester,
    ) async {
      await pumpPage(
        tester,
        orders: [buildOrder()],
        deliveryRepo: InMemoryDeliveryRepository(
          seed: [
            buildAssignment(
              driverName: 'منى السيد',
              driverPhone: '01122334455',
              driverRating: 4.7,
              vehicleInfo: 'تويوتا هايس • لوحة ٤٥٢١',
            ),
          ],
        ),
      );

      expect(find.text('منى السيد'), findsOneWidget);
      expect(find.textContaining('تقييم المندوب: 4.7'), findsOneWidget);
      expect(find.text('تويوتا هايس • لوحة ٤٥٢١'), findsOneWidget);

      // Phone action surfaces the REAL assigned driver's number.
      await tester.tap(find.byIcon(Icons.phone));
      await tester.pump();
      expect(find.textContaining('01122334455'), findsOneWidget);
    });

    testWidgets('falls back to generic placeholder when assignment has no '
        'profile enrichment', (tester) async {
      await pumpPage(
        tester,
        orders: [buildOrder()],
        deliveryRepo: InMemoryDeliveryRepository(seed: [buildAssignment()]),
      );

      expect(find.text('مندوب التوصيل'), findsOneWidget);
    });
  });

  group('Driver chat entry point', () {
    testWidgets('hidden when no assignment exists yet', (tester) async {
      await pumpPage(
        tester,
        orders: [buildOrder()],
        deliveryRepo: InMemoryDeliveryRepository(seed: const []),
      );

      expect(find.text('محادثة السائق'), findsNothing);
    });

    testWidgets('visible once a driver is assigned', (tester) async {
      await pumpPage(
        tester,
        orders: [buildOrder()],
        deliveryRepo: InMemoryDeliveryRepository(seed: [buildAssignment()]),
      );

      expect(find.text('محادثة السائق'), findsOneWidget);
    });
  });

  group('Driver location event filtering', () {
    const orderId = 'ORD-TRK-1';

    test('accepts payloads carrying the matching orderId', () {
      expect(
        driverLocationTargetsOrder(
          payload: {'orderId': orderId, 'latitude': 30.0, 'longitude': 31.0},
          orderId: orderId,
        ),
        isTrue,
      );
    });

    test('rejects payloads scoped to another order', () {
      expect(
        driverLocationTargetsOrder(
          payload: {'orderId': 'ORD-OTHER', 'latitude': 30.0},
          orderId: orderId,
          assignedDriverId: 'driver-x',
        ),
        isFalse,
      );
    });

    test(
      'legacy payload (no orderId) accepted only for the assigned driver',
      () {
        expect(
          driverLocationTargetsOrder(
            payload: {'driverId': 'driver-x'},
            orderId: orderId,
            assignedDriverId: 'driver-x',
          ),
          isTrue,
        );
        expect(
          driverLocationTargetsOrder(
            payload: {'driverId': 'driver-other'},
            orderId: orderId,
            assignedDriverId: 'driver-x',
          ),
          isFalse,
        );
      },
    );

    test('legacy payload rejected before any assignment is known', () {
      expect(
        driverLocationTargetsOrder(
          payload: {'driverId': 'driver-x'},
          orderId: orderId,
        ),
        isFalse,
      );
    });

    testWidgets('page ignores realtime location events for other orders', (
      tester,
    ) async {
      await pumpPage(
        tester,
        orders: [buildOrder()],
        deliveryRepo: InMemoryDeliveryRepository(seed: [buildAssignment()]),
      );

      final context = tester.element(find.byType(OrderTrackingPage));
      final container = ProviderScope.containerOf(context);
      final realtime = container.read(realtimeServiceProvider);

      // Events for OTHER orders / unknown legacy drivers must not crash or
      // corrupt the tracking page.
      realtime.broadcastDriverLocation(
        driverId: 'driver-x',
        latitude: 99.0,
        longitude: 99.0,
        orderId: 'ORD-OTHER',
      );
      await tester.pump(const Duration(milliseconds: 50));

      // An event scoped to THIS order flows through the filter cleanly.
      realtime.broadcastDriverLocation(
        driverId: 'driver-x',
        latitude: 30.05,
        longitude: 31.24,
        orderId: orderId,
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
    });
  });
}

class OrdersControllerMock extends StateNotifier<List<OrderEntity>>
    implements OrdersController {
  OrdersControllerMock(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Records cancellations and applies them to state like the real controller.
class FakeOrdersController extends StateNotifier<List<OrderEntity>>
    implements OrdersController {
  FakeOrdersController(super.state);

  final List<String> cancelledOrderIds = [];

  @override
  Future<OrderEntity?> updateStatus(String orderId, OrderStatus status) async {
    if (status == OrderStatus.cancelled) cancelledOrderIds.add(orderId);
    state = [
      for (final o in state)
        if (o.id == orderId) o.copyWith(status: status) else o,
    ];
    for (final o in state) {
      if (o.id == orderId) return o;
    }
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
