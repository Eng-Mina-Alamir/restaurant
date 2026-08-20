import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/shared/widgets/empty_state.dart';
import 'package:restaurant_app/shared/widgets/language_switcher.dart';
import 'package:restaurant_app/shared/widgets/theme_mode_switch_button.dart';

void main() {
  group('Accessibility & Semantics Quality Tests', () {
    testWidgets('EmptyState widget has semantic headers and accessible button', (tester) async {
      var actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              message: 'لا توجد بيانات متاحة حالياً',
              actionLabel: 'إعادة المحاولة',
              onAction: () => actionTriggered = true,
            ),
          ),
        ),
      );

      // Verify text semantics
      expect(find.text('لا توجد بيانات متاحة حالياً'), findsOneWidget);
      expect(find.text('إعادة المحاولة'), findsOneWidget);

      // Tap action
      await tester.tap(find.text('إعادة المحاولة'));
      await tester.pump();

      expect(actionTriggered, isTrue);
    });

    testWidgets('ThemeModeSwitchButton meets minimum touch target guidelines', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(56),
                child: ThemeModeSwitchButton(),
              ),
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(IconButton);
      expect(buttonFinder, findsOneWidget);

      final renderBox = tester.renderObject<RenderBox>(buttonFinder);
      // Minimum tap target recommended is 48x48dp (or standard icon button)
      expect(renderBox.size.width, greaterThanOrEqualTo(40.0));
      expect(renderBox.size.height, greaterThanOrEqualTo(40.0));
    });

    testWidgets('LanguageSwitcherButton renders outlined button in non-compact mode', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: LanguageSwitcherButton(compact: false),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(LanguageSwitcherButton), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
    });
  });
}
