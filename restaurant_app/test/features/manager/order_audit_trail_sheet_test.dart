import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/errors/either.dart';
import 'package:restaurant_app/core/errors/failures.dart';
import 'package:restaurant_app/core/utils/formatters.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/data/repositories/in_memory_order_repository.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_status_log_entry.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';
import 'package:restaurant_app/features/table_management/presentation/pages/all_orders_page.dart';
import 'package:restaurant_app/features/table_management/presentation/widgets/order_audit_trail_sheet.dart';
import '../../helpers/test_container.dart';

/// [InMemoryOrderRepository] double seeded with fixed audit trails so sheet
/// tests can render known transitions (including non-revert entries, which
/// the real in-memory repository never logs).
class _SeededTrailOrderRepository extends InMemoryOrderRepository {
  _SeededTrailOrderRepository(this._trails);

  final Map<String, List<OrderStatusLogEntry>> _trails;

  @override
  Future<Either<Failure, List<OrderStatusLogEntry>>> getAuditTrail(
    String orderId,
  ) async {
    return Right<Failure, List<OrderStatusLogEntry>>(
      List<OrderStatusLogEntry>.of(_trails[orderId] ?? const []),
    );
  }
}

OrderStatusLogEntry _entry({
  required OrderStatus from,
  required OrderStatus to,
  required String actorId,
  required DateTime createdAt,
  bool isRevert = false,
  String? reason,
}) {
  return OrderStatusLogEntry(
    orderId: 'ORD-0001',
    fromStatus: from,
    toStatus: to,
    actorId: actorId,
    reason: reason,
    isRevert: isRevert,
    createdAt: createdAt,
  );
}

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

  final t1 = DateTime(2026, 8, 1, 10);
  final t2 = DateTime(2026, 8, 1, 11);
  final t3 = DateTime(2026, 8, 1, 12);

  ProviderContainer seededContainer() {
    final repo = _SeededTrailOrderRepository(
      <String, List<OrderStatusLogEntry>>{
        // Oldest-first chronological trail: one normal transition followed by
        // two guarded reverts.
        'ORD-0001': <OrderStatusLogEntry>[
          _entry(
            from: OrderStatus.pending,
            to: OrderStatus.confirmed,
            actorId: 'staff-1',
            createdAt: t1,
          ),
          _entry(
            from: OrderStatus.ready,
            to: OrderStatus.preparing,
            actorId: 'chef-9',
            createdAt: t2,
            isRevert: true,
            reason: 'تم التجهيز بالخطأ',
          ),
          _entry(
            from: OrderStatus.served,
            to: OrderStatus.ready,
            actorId: 'waiter-3',
            createdAt: t3,
            isRevert: true,
            reason: 'لم يستلم العميل الطلب',
          ),
        ],
      },
    );
    return createTestContainer(
      additionalOverrides: [orderRepositoryProvider.overrideWithValue(repo)],
    );
  }

  Future<void> pumpSheet(WidgetTester tester, ProviderContainer container) {
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: OrderAuditTrailSheet(orderId: 'ORD-0001')),
        ),
      ),
    );
  }

  testWidgets('renders three chronological rows with chips, reasons and '
      'revert badges', (tester) async {
    final container = seededContainer();
    addTearDown(container.dispose);

    await pumpSheet(tester, container);
    await tester.pumpAndSettle();

    // Transition labels for all three entries are present.
    expect(find.text('قيد الانتظار'), findsOneWidget);
    expect(find.text('مؤكد'), findsOneWidget);
    expect(find.text('قيد التحضير'), findsOneWidget);
    // `ready` appears as from-chip of the first revert and to-chip of the
    // second one; `served` has no Arabic mapping and renders raw.
    expect(find.text('جاهز'), findsNWidgets(2));
    expect(find.text('served'), findsOneWidget);

    // Reason lines only on the two reverts.
    expect(find.textContaining('السبب'), findsNWidgets(2));

    // Distinct تراجع badge on each revert entry.
    expect(find.text('تراجع'), findsNWidgets(2));

    // Formatted timestamps rendered per row.
    expect(find.text(Formatters.formatDateTime(t1)), findsOneWidget);
    expect(find.text(Formatters.formatDateTime(t2)), findsOneWidget);
    expect(find.text(Formatters.formatDateTime(t3)), findsOneWidget);

    // Rows are ordered oldest-first (chronological top-to-bottom).
    final y1 = tester.getTopLeft(find.text(Formatters.formatDateTime(t1))).dy;
    final y2 = tester.getTopLeft(find.text(Formatters.formatDateTime(t2))).dy;
    final y3 = tester.getTopLeft(find.text(Formatters.formatDateTime(t3))).dy;
    expect(y1, lessThan(y2));
    expect(y2, lessThan(y3));
  });

  testWidgets('shows Arabic empty state when the order has no log', (
    tester,
  ) async {
    final container = seededContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: OrderAuditTrailSheet(orderId: 'ORD-9999')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('لا يوجد سجل لهذا الطلب'), findsOneWidget);
  });

  testWidgets('tapping the history icon on an order card opens the sheet', (
    tester,
  ) async {
    final container = createTestContainer(seedCheckoutFixtures: true);
    addTearDown(container.dispose);
    await primeMenuForCheckout(container);
    container
        .read(cartControllerProvider.notifier)
        .addItem(const CartItem(menuItem: burger, quantity: 1));
    await container
        .read(ordersControllerProvider.notifier)
        .placeOrderForTable('t1');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AllOrdersPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();

    expect(find.text('سجل الحالة'), findsOneWidget);
    // A freshly placed order has no logged transitions yet.
    expect(find.text('لا يوجد سجل لهذا الطلب'), findsOneWidget);
  });
}
