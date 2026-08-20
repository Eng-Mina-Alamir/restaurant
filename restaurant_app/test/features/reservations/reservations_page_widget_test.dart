import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:restaurant_app/features/reservations/presentation/pages/reservations_page.dart';
import '../../helpers/test_container.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar');
  });

  group('ReservationsPage Widget Tests', () {
    testWidgets('renders reservations list and filter chips', (tester) async {
      final container = createTestContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ReservationsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('إدارة الحجوزات'), findsOneWidget);
      expect(find.text('كل الحجوزات'), findsOneWidget);
      expect(find.text('حجز طاولة'), findsOneWidget);
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('tapping add reservation opens bottom sheet', (tester) async {
      final container = createTestContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ReservationsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      expect(find.text('حجز طاولة جديد'), findsOneWidget);
      expect(find.text('اسم العميل *'), findsOneWidget);
      expect(find.text('رقم الهاتف *'), findsOneWidget);
      expect(find.text('تأكيد وحفظ الحجز'), findsOneWidget);
    });
  });
}
