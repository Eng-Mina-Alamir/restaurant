import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/config/environment.dart';

void main() {
  group('EnvironmentConfig Tests', () {
    test('current environment is defined', () {
      expect(EnvironmentConfig.current, isA<Environment>());
      expect(EnvironmentConfig.isProduction, isTrue);
      expect(EnvironmentConfig.baseUrl, isNotEmpty);
      expect(EnvironmentConfig.baseUrl, startsWith('http'));
      expect(EnvironmentConfig.wsUrl, startsWith('ws'));
    });

    test('Environment enum has all targets', () {
      expect(Environment.values, containsAll([
        Environment.dev,
        Environment.staging,
        Environment.production,
      ]));
    });
  });
}
