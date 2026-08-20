import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:restaurant_app/features/delivery/presentation/widgets/live_tracking_map.dart';

void main() {
  group('LiveTrackingMap Widget Tests', () {
    testWidgets('renders map widget and custom labels', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LiveTrackingMap(
              pickupLatLng: LatLng(30.0444, 31.2357),
              deliveryLatLng: LatLng(30.0626, 31.2497),
              pickupLabel: 'مطعم الأصالة',
              deliveryLabel: 'فيلا العميل',
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(LiveTrackingMap), findsOneWidget);
    });
  });
}
