import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/theme/theme_controller.dart';

void main() {
  group('ThemeModeController Tests', () {
    test('defaults to ThemeMode.system and updates correctly', () async {
      final controller = ThemeModeController();
      expect(controller.state, equals(ThemeMode.system));

      await controller.setThemeMode(ThemeMode.dark);
      expect(controller.state, equals(ThemeMode.dark));

      await controller.setThemeMode(ThemeMode.light);
      expect(controller.state, equals(ThemeMode.light));

      await controller.toggleTheme(Brightness.light);
      expect(controller.state, equals(ThemeMode.dark));

      await controller.toggleTheme(Brightness.dark);
      expect(controller.state, equals(ThemeMode.light));
    });
  });
}
