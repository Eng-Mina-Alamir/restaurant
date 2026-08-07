import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/table_management/domain/entities/restaurant_table.dart';
import 'package:restaurant_app/features/table_management/presentation/pages/waiter_table_card.dart';

void main() {
  const availableTable = RestaurantTable(
    id: 't1',
    tableNumber: 1,
    capacity: 4,
    location: 'تراس',
    status: TableStatus.available,
  );

  const occupiedTable = RestaurantTable(
    id: 't2',
    tableNumber: 2,
    capacity: 6,
    location: 'صالة',
    status: TableStatus.occupied,
    currentOrderId: 'ORD-0001',
  );

  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('shows table number, status, capacity and location', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const WaiterTableCard(
          table: availableTable,
          onTap: _noop,
          onTakeOrder: _noop,
          onRelease: _noop,
          onReserve: _noop,
        ),
      ),
    );

    expect(find.text('1'), findsOneWidget);
    expect(find.text(TableStatus.available.labelAr), findsOneWidget);
    expect(find.textContaining('4 مقاعد'), findsOneWidget);
    expect(find.text('تراس'), findsOneWidget);
  });

  testWidgets('shows a friendly order number for an occupied table', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const WaiterTableCard(
          table: occupiedTable,
          onTap: _noop,
          onTakeOrder: _noop,
          onRelease: _noop,
          onReserve: _noop,
        ),
      ),
    );

    // ORD-0001 → #1 (no raw ORD- prefix).
    expect(find.text('#1'), findsOneWidget);
    expect(find.textContaining('ORD-0001'), findsNothing);
  });

  testWidgets('fires action callbacks from the card buttons', (tester) async {
    var tapped = 0;
    var taken = 0;
    var released = 0;
    var reserved = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WaiterTableCard(
            table: availableTable,
            onTap: () => tapped++,
            onTakeOrder: () => taken++,
            onRelease: () => released++,
            onReserve: () => reserved++,
          ),
        ),
      ),
    );

    await tester.tap(find.text('أخذ الطلب'));
    await tester.tap(find.byTooltip('حجز'));
    await tester.tap(find.byTooltip('تسليم الطاولة'));
    await tester.pump();

    expect(taken, 1);
    expect(reserved, 1);
    expect(released, 1);
    expect(tapped, 0);
  });
}

void _noop() {}
