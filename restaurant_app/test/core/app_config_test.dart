import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/config/app_config.dart';

void main() {
  group('AppConfig Tests', () {
    test('verifies core application configuration properties', () {
      expect(AppConfig.appName, isNotEmpty);
      expect(AppConfig.appTagline, isNotEmpty);
      expect(AppConfig.version, '1.0.0');
      expect(AppConfig.defaultCurrency, isNotEmpty);
      expect(AppConfig.locale, 'ar');
      expect(AppConfig.fallbackLocale, 'en');
      expect(AppConfig.supportedLocales, containsAll(['ar', 'en']));
      expect(AppConfig.useDemoAuth, isFalse);
      expect(AppConfig.useSupabase, isTrue);
    });
  });
}
