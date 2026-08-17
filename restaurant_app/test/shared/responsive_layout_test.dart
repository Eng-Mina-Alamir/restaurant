import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/shared/widgets/responsive_layout.dart';

void main() {
  group('AppBreakpoints', () {
    test('gridColumnsForWidth calculates optimal columns', () {
      expect(AppBreakpoints.gridColumnsForWidth(400), 2);
      expect(AppBreakpoints.gridColumnsForWidth(750), 3);
      expect(AppBreakpoints.gridColumnsForWidth(1100), 4);
      expect(AppBreakpoints.gridColumnsForWidth(1400), 5);
    });
  });

  group('ResponsiveLayout Widget', () {
    testWidgets('renders mobile widget on small screens', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: ResponsiveLayout(
            mobile: Text('Mobile View'),
            tablet: Text('Tablet View'),
            desktop: Text('Desktop View'),
          ),
        ),
      );

      expect(find.text('Mobile View'), findsOneWidget);
      expect(find.text('Tablet View'), findsNothing);
      expect(find.text('Desktop View'), findsNothing);
    });

    testWidgets('renders tablet widget on medium screens', (tester) async {
      tester.view.physicalSize = const Size(800, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: ResponsiveLayout(
            mobile: Text('Mobile View'),
            tablet: Text('Tablet View'),
            desktop: Text('Desktop View'),
          ),
        ),
      );

      expect(find.text('Tablet View'), findsOneWidget);
      expect(find.text('Mobile View'), findsNothing);
      expect(find.text('Desktop View'), findsNothing);
    });

    testWidgets('renders desktop widget on large screens', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: ResponsiveLayout(
            mobile: Text('Mobile View'),
            tablet: Text('Tablet View'),
            desktop: Text('Desktop View'),
          ),
        ),
      );

      expect(find.text('Desktop View'), findsOneWidget);
      expect(find.text('Mobile View'), findsNothing);
      expect(find.text('Tablet View'), findsNothing);
    });
  });

  group('ResponsiveBuilder Widget', () {
    testWidgets('provides correct ScreenType', (tester) async {
      tester.view.physicalSize = const Size(700, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      ScreenType? detected;

      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveBuilder(
            builder: (context, screenType, constraints) {
              detected = screenType;
              return Text('Type: ${screenType.name}');
            },
          ),
        ),
      );

      expect(detected, ScreenType.tablet);
      expect(find.text('Type: tablet'), findsOneWidget);
    });
  });
}
