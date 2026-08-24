import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/customer/presentation/pages/qr_scan_page.dart';

void main() {
  group('QrScanPage Widget Tests', () {
    testWidgets('renders QR scan page with app bar and instruction text', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: QrScanPage())),
      );

      // Verify app bar title
      expect(find.text('مسح رمز QR الطاولة'), findsOneWidget);

      // Verify flash and switch camera action icons
      expect(find.byIcon(Icons.flash_on), findsOneWidget);
      expect(find.byIcon(Icons.flip_camera_ios), findsOneWidget);

      // Verify guidance / instructions for user in Arabic
      expect(
        find.text('وجّه الكاميرا نحو رمز QR الموجود على الطاولة'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget);
    });
  });
}
