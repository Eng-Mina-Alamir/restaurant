import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/shared/animations/shimmer_loading.dart';

void main() {
  group('ShimmerLoading & SkeletonBox Widget Tests', () {
    testWidgets('renders SkeletonBox with custom dimensions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SkeletonBox(width: 150, height: 40, borderRadius: 12),
            ),
          ),
        ),
      );

      expect(find.byType(SkeletonBox), findsOneWidget);
      expect(find.byType(ShimmerLoading), findsOneWidget);
    });

    testWidgets('ShimmerLoading animates over duration without errors', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: ShimmerLoading(child: Text('جاري التحميل...'))),
          ),
        ),
      );

      expect(find.text('جاري التحميل...'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
    });
  });
}
