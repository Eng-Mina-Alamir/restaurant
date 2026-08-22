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

  /// Keeps seeded-assignment widget tests offline: the shared provider routes
  /// to Supabase when AppConfig.useSupabase is enabled (same pattern as the
  /// orderRepositoryProvider overrides in test/helpers/test_container.dart).
  List<Override> offlineOverrides() => [
        deliveryRepositoryProvider.overrideWithValue(
          InMemoryDeliveryRepository(),
        ),
      ];

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
      ProviderScope(
        overrides: offlineOverrides(),
        child: const MaterialApp(home: DriverHomePage()),
      ),
    );
    await tester.pumpAndSettle();

    // Two seeded demo assignments (formatted as friendly order numbers).
    expect(find.textContaining('#101'), findsOneWidget);
    expect(find.textContaining('#104'), findsOneWidget);

    // Distance formatted for the first card (>1km -> km).
    expect(find.textContaining('2.4 كم'), findsOneWidget);
    expect(find.textContaining('المسافة:'), findsWidgets);
    expect(find.textContaining('وقت الجهوزية:'), findsWidgets);
    // Delivery fee uses its own label rather than the generic total label.
    expect(find.textContaining('رسوم التوصيل:'), findsWidgets);
    expect(find.textContaining('الإجمالي:'), findsNothing);
    // Customer phone is shown for coordination.
    expect(find.textContaining('رقم العميل: 0551234567'), findsOneWidget);
  });

  testWidgets('shows a contextual empty message for a status with no jobs', (
    tester,
  ) async {
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
    await tester.pumpAndSettle();

    // Filter to "delivered" which has no seeded jobs.
    final deliveredChip = find.widgetWithText(
      ChoiceChip,
      AppConstants.deliveryDelivered,
    );
    await tester.ensureVisible(deliveredChip);
    await tester.pumpAndSettle();
    await tester.tap(deliveredChip);
    await tester.pumpAndSettle();

    expect(
      find.text(
        '${AppConstants.deliveryDelivered} — ${AppConstants.noDeliveryJobs}',
      ),
      findsOneWidget,
    );
  });

  testWidgets('filters assignments by status chip', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: offlineOverrides(),
        child: const MaterialApp(home: DriverHomePage()),
      ),
    );
    await tester.pumpAndSettle();

    // Both seeded assignments visible initially.
    expect(find.textContaining('#101'), findsOneWidget);
    expect(find.textContaining('#104'), findsOneWidget);

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
    expect(find.textContaining('#101'), findsOneWidget);
    expect(find.textContaining('#104'), findsOneWidget);
  });

  testWidgets('action button advances a pending assignment to accepted', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: offlineOverrides(),
        child: const MaterialApp(home: DriverHomePage()),
      ),
    );
    await tester.pumpAndSettle();

    // First assignment is pending -> shows the accept action.
    final acceptButton = find.widgetWithText(
      FilledButton,
      AppConstants.actionAccept,
    );
    expect(acceptButton, findsOneWidget);
    expect(
      find.text(AppConstants.actionStartDelivery),
      findsOneWidget, // second assignment is already accepted
    );

    await tester.tap(acceptButton);
    await tester.pumpAndSettle();

    // Now both are accepted: no pending accept action remains.
    expect(
      find.widgetWithText(FilledButton, AppConstants.actionAccept),
      findsNothing,
    );
    expect(find.text(AppConstants.actionStartDelivery), findsNWidgets(2));
  });
}
