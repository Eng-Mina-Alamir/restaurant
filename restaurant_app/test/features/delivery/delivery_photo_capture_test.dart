import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/delivery/presentation/widgets/delivery_photo_capture.dart';

void main() {
  group('DeliveryPhotoCapture Widget Tests', () {
    testWidgets('renders placeholder card and source buttons when no photo', (
      tester,
    ) async {
      File? selectedPhoto;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeliveryPhotoCapture(
              onPhotoSelected: (photo) {
                selectedPhoto = photo;
              },
            ),
          ),
        ),
      );

      expect(find.text('صورة توثيق التسليم'), findsOneWidget);
      expect(find.text('اضغط لالتقاط صورة التسليم'), findsOneWidget);
      expect(find.text('الكاميرا'), findsOneWidget);
      expect(find.text('المعرض'), findsOneWidget);
      expect(selectedPhoto, isNull);

      // Tap placeholder to open bottom sheet modal
      await tester.tap(find.text('اضغط لالتقاط صورة التسليم'));
      await tester.pumpAndSettle();

      expect(find.text('اختيار من المعرض'), findsOneWidget);
    });
  });
}
