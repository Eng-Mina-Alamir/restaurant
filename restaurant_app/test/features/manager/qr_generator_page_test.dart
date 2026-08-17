import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/manager_dashboard/presentation/pages/qr_generator_page.dart';

void main() {
  group('QrGeneratorPage', () {
    testWidgets('renders QR codes for restaurant tables', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: QrGeneratorPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('رموز QR الطاولات'), findsOneWidget);
      expect(find.textContaining('طاولة'), findsWidgets);
    });
  });
}
