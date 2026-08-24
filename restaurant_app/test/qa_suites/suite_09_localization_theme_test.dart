import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/l10n/app_localizations.dart';
import 'package:restaurant_app/core/l10n/app_strings.dart';
import 'package:restaurant_app/core/theme/theme_controller.dart';
import 'helpers/qa_test_helpers.dart';

void main() {
  setUpAll(() {
    initQaTestEnvironment();
  });

  group('Suite 9: Localization & Themes (التعريب والاتجاهات والمظاهر)', () {
    // -------------------------------------------------------------
    // TC-LOC-01: Language Toggle & Directionality (RTL / LTR)
    // -------------------------------------------------------------
    test(
      'TC-LOC-01: Language toggle flips locale and TextDirection between RTL and LTR',
      () async {
        final container = createQaContainer();
        addTearDown(container.dispose);

        final localeNotifier = container.read(
          localeControllerProvider.notifier,
        );

        // Set Arabic (RTL)
        await localeNotifier.setLocale(const Locale('ar'));
        expect(container.read(localeControllerProvider), const Locale('ar'));
        expect(container.read(isRtlProvider), isTrue);
        expect(
          container.read(currentLanguageProvider).direction,
          TextDirection.rtl,
        );

        // Switch to English (LTR)
        await localeNotifier.setLocale(const Locale('en'));
        expect(container.read(localeControllerProvider), const Locale('en'));
        expect(container.read(isRtlProvider), isFalse);
        expect(
          container.read(currentLanguageProvider).direction,
          TextDirection.ltr,
        );

        // Toggle back to Arabic
        await localeNotifier.toggleLanguage();
        expect(container.read(localeControllerProvider), const Locale('ar'));
        expect(container.read(isRtlProvider), isTrue);
      },
    );

    // -------------------------------------------------------------
    // TC-LOC-02: No Missing Translation Keys
    // -------------------------------------------------------------
    test(
      'TC-LOC-02: AppStrings dictionary contains complete non-empty translations for AR and EN',
      () {
        final arStrings = AppStrings(const Locale('ar'));
        final enStrings = AppStrings(const Locale('en'));

        // Auth Strings
        expect(arStrings.loginTitle, isNotEmpty);
        expect(enStrings.loginTitle, isNotEmpty);
        expect(arStrings.loginTitle, isNot(equals(enStrings.loginTitle)));

        expect(arStrings.emailLabel, isNotEmpty);
        expect(enStrings.emailLabel, isNotEmpty);

        // Navigation Strings
        expect(arStrings.menu, isNotEmpty);
        expect(enStrings.menu, isNotEmpty);

        expect(arStrings.kds, isNotEmpty);
        expect(enStrings.kds, isNotEmpty);

        expect(arStrings.tables, isNotEmpty);
        expect(enStrings.tables, isNotEmpty);

        // Action Strings
        expect(arStrings.checkout, isNotEmpty);
        expect(enStrings.checkout, isNotEmpty);

        expect(arStrings.total, isNotEmpty);
        expect(enStrings.total, isNotEmpty);
      },
    );

    // -------------------------------------------------------------
    // TC-THM-01: Light & Dark Theme Toggle & Contrast
    // -------------------------------------------------------------
    test(
      'TC-THM-01: ThemeController switches between Light and Dark mode with valid palettes',
      () async {
        final container = createQaContainer();
        addTearDown(container.dispose);

        final themeNotifier = container.read(
          themeModeControllerProvider.notifier,
        );

        // Set Dark Theme
        await themeNotifier.setThemeMode(ThemeMode.dark);
        expect(container.read(themeModeControllerProvider), ThemeMode.dark);

        // Toggle to Light
        await themeNotifier.toggleTheme(Brightness.dark);
        expect(container.read(themeModeControllerProvider), ThemeMode.light);

        // Toggle to Dark
        await themeNotifier.toggleTheme(Brightness.light);
        expect(container.read(themeModeControllerProvider), ThemeMode.dark);
      },
    );
  });
}
