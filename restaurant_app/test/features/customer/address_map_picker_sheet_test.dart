import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:restaurant_app/features/customer/presentation/widgets/address_map_picker_sheet.dart';
import '../../helpers/test_http_overrides.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = TestHttpOverrides();
  });

  group('AddressMapPickerSheet Widget Tests', () {
    testWidgets('renders search bar, map, and confirmation button', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AddressMapPickerSheet(
              initialLatLng: LatLng(30.0444, 31.2357),
              title: 'تحديد عنوان التوصيل على الخريطة',
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('تحديد عنوان التوصيل على الخريطة'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('تأكيد هذا العنوان ومتابعة الطلب'), findsOneWidget);
      expect(find.byIcon(Icons.location_pin), findsWidgets);
    });

    testWidgets('allows typing in the search bar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AddressMapPickerSheet())),
      );

      await tester.pump();
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'المعادي شارع النصر');
      await tester.pump();

      expect(find.text('المعادي شارع النصر'), findsOneWidget);
    });
  });
}
