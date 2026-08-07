import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:restaurant_app/config/constants.dart';
import 'package:restaurant_app/features/delivery/data/repositories/in_memory_delivery_repository.dart';
import 'package:restaurant_app/features/delivery/presentation/controllers/delivery_controller.dart';
import 'package:restaurant_app/features/delivery/presentation/pages/driver_home_page.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar');
  });

  testWidgets('shows empty state when no delivery jobs', (tester) async {
    final container = ProviderContainer(
      overrides: [
        deliveryRepositoryProvider.overrideWithValue(
          InMemoryDeliveryRepository(seed: const []),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: DriverHomePage()),
      ),
    );
    await tester.pump();
    expect(find.text('لا توجد مهام توصيل حالياً'), findsOneWidget);
  });

  testWidgets('renders assignment cards with location, pickup and distance', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: DriverHomePage())),
    );
    await tester.pumpAndSettle();

    // Two seeded demo assignments.
    expect(find.textContaining('#ORD-0101'), findsOneWidget);
    expect(find.textContaining('#ORD-0104'), findsOneWidget);

    // Distance formatted for the first card (>1km -> km).
    expect(find.textContaining('2.4 كم'), findsOneWidget);
    expect(find.textContaining('المسافة:'), findsWidgets);
    expect(find.textContaining('وقت الجهوزية:'), findsWidgets);
  });

  testWidgets('filters assignments by status chip', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: DriverHomePage())),
    );
    await tester.pumpAndSettle();

    // Both seeded assignments visible initially.
    expect(find.textContaining('#ORD-0101'), findsOneWidget);
    expect(find.textContaining('#ORD-0104'), findsOneWidget);

    // Filter to pending only — the accepted assignment disappears.
    await tester.tap(
      find.widgetWithText(ChoiceChip, AppConstants.deliveryPending),
    );
    await tester.pumpAndSettle();

    // Back to "all" restores both.
    await tester.tap(
      find.widgetWithText(ChoiceChip, AppConstants.driverFilterAll),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('#ORD-0101'), findsOneWidget);
    expect(find.textContaining('#ORD-0104'), findsOneWidget);
  });
}
