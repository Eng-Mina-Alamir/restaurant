import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/utils/image_utils.dart';

void main() {
  group('AppImageUtils Widget & Unit Tests', () {
    testWidgets('buildOptimizedImage renders widget tree', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppImageUtils.buildOptimizedImage(
              imageUrl: 'https://example.com/burger.png',
              width: 100,
              height: 100,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );

      expect(find.byType(ClipRRect), findsOneWidget);
    });

    testWidgets('buildGradientBanner renders title, subtitle, and icon', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppImageUtils.buildGradientBanner(
              title: 'خصم خاص 20%',
              subtitle: 'استخدم كود SAVE20',
              icon: Icons.local_offer,
            ),
          ),
        ),
      );

      expect(find.text('خصم خاص 20%'), findsOneWidget);
      expect(find.text('استخدم كود SAVE20'), findsOneWidget);
      expect(find.byIcon(Icons.local_offer), findsOneWidget);
    });
  });
}
