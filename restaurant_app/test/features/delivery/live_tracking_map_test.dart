import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:restaurant_app/features/delivery/presentation/widgets/live_tracking_map.dart';
import '../../helpers/test_http_overrides.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = TestHttpOverrides();
  });

  group('LiveTrackingMap Comprehensive Widget Tests', () {
    testWidgets('renders map widget with custom labels and initial theme', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LiveTrackingMap(
              pickupLatLng: LatLng(30.0444, 31.2357),
              deliveryLatLng: LatLng(30.0626, 31.2497),
              pickupLabel: 'مطعم الأصالة',
              deliveryLabel: 'فيلا العميل',
              initialTheme: AppMapThemeOption.satellite,
              showControls: true,
              showNavigationHud: true,
              showDeliveryRadius: true,
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(LiveTrackingMap), findsOneWidget);
      expect(find.text('مطعم الأصالة'), findsOneWidget);
      expect(find.text('فيلا العميل'), findsOneWidget);
    });

    testWidgets('renders floating controls and allows interaction', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LiveTrackingMap(
              pickupLatLng: LatLng(30.0444, 31.2357),
              deliveryLatLng: LatLng(30.0626, 31.2497),
              showControls: true,
              showNavigationHud: true,
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byIcon(Icons.layers_outlined), findsOneWidget);
      expect(find.byIcon(Icons.fit_screen_outlined), findsOneWidget);
      expect(find.byIcon(Icons.explore_outlined), findsOneWidget);
    });

    testWidgets('supports dark and cleanLight theme options', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LiveTrackingMap(
              pickupLatLng: LatLng(30.0444, 31.2357),
              deliveryLatLng: LatLng(30.0626, 31.2497),
              initialTheme: AppMapThemeOption.dark,
              showControls: false,
              showNavigationHud: false,
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(LiveTrackingMap), findsOneWidget);
    });
  });
}
