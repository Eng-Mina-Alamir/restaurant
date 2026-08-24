import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/ratings/domain/entities/rating_entity.dart';
import 'package:restaurant_app/features/ratings/presentation/widgets/rating_dialog.dart';

void main() {
  group('RatingDialog Widget Tests', () {
    testWidgets('renders star rating, comment box and submits rating', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => RatingDialog.show(
                    context,
                    targetId: 'item-101',
                    targetType: RatingTargetType.menuItem,
                    title: 'تقييم الوجبة',
                    subtitle: 'كيف كانت جودة الطعام؟',
                  ),
                  child: const Text('Rate Now'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Rate Now'));
      await tester.pumpAndSettle();

      expect(find.text('تقييم الوجبة'), findsOneWidget);
      expect(find.text('كيف كانت جودة الطعام؟'), findsOneWidget);
      expect(find.text('إرسال التقييم'), findsOneWidget);
      expect(find.text('لاحقاً'), findsOneWidget);

      // Enter comment
      await tester.enterText(find.byType(TextField), 'أفضل مطعم على الإطلاق!');
      await tester.pump();

      // Submit
      await tester.tap(find.text('إرسال التقييم'));
      await tester.pumpAndSettle();

      expect(find.text('شكراً لمشاركتنا تقييمك القيّم!'), findsOneWidget);
    });
  });
}
