import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/l10n/app_localizations.dart';
import 'package:restaurant_app/shared/widgets/language_switcher.dart';

void main() {
  group('LanguageSwitcherButton Widget Tests', () {
    testWidgets('renders full button and toggles language on tap', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: Center(child: LanguageSwitcherButton())),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LanguageSwitcherButton), findsOneWidget);

      final initialLang = container.read(currentLanguageProvider);
      await tester.tap(find.byType(LanguageSwitcherButton));
      await tester.pumpAndSettle();

      final newLang = container.read(currentLanguageProvider);
      expect(newLang, isNot(initialLang));
    });

    testWidgets('renders compact icon button mode', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(child: LanguageSwitcherButton(compact: true)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.language_rounded), findsOneWidget);
    });
  });
}
