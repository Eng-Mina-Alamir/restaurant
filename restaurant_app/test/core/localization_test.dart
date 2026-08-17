import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/l10n/app_localizations.dart';

void main() {
  group('AppLanguage and LocaleController', () {
    test('AppLanguage maps locale and direction correctly', () {
      expect(AppLanguage.arabic.locale, const Locale('ar'));
      expect(AppLanguage.arabic.direction, TextDirection.rtl);
      expect(AppLanguage.arabic.displayName, 'العربية');

      expect(AppLanguage.english.locale, const Locale('en'));
      expect(AppLanguage.english.direction, TextDirection.ltr);
      expect(AppLanguage.english.displayName, 'English');

      expect(AppLanguage.fromLocale(const Locale('en')), AppLanguage.english);
      expect(AppLanguage.fromLocale(const Locale('ar')), AppLanguage.arabic);
    });

    test('LocaleController defaults to Arabic and toggles correctly', () async {
      final controller = LocaleController();
      expect(controller.state, const Locale('ar'));

      await controller.toggleLanguage();
      expect(controller.state, const Locale('en'));

      await controller.toggleLanguage();
      expect(controller.state, const Locale('ar'));

      await controller.setLanguage(AppLanguage.english);
      expect(controller.state, const Locale('en'));
    });

    test('Providers reflect active language and RTL state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(isRtlProvider), isTrue);
      expect(container.read(currentLanguageProvider), AppLanguage.arabic);

      await container.read(localeControllerProvider.notifier).setLanguage(AppLanguage.english);
      expect(container.read(isRtlProvider), isFalse);
      expect(container.read(currentLanguageProvider), AppLanguage.english);
    });
  });
}
