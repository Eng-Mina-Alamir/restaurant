import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/theme/theme_controller.dart';
import 'package:restaurant_app/shared/widgets/theme_mode_switch_button.dart';

void main() {
  group('ThemeModeSwitchButton Widget Tests', () {
    testWidgets('renders theme toggle icon button and toggles theme on tap', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(56),
                child: Center(child: ThemeModeSwitchButton()),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ThemeModeSwitchButton), findsOneWidget);

      final initialTheme = container.read(themeModeControllerProvider);
      await tester.tap(find.byType(ThemeModeSwitchButton));
      await tester.pumpAndSettle();

      final newTheme = container.read(themeModeControllerProvider);
      expect(newTheme, isNot(initialTheme));
    });
  });
}
