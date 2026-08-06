import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:restaurant_app/config/app_config.dart';
import 'package:restaurant_app/config/environment.dart';
import 'package:restaurant_app/core/errors/either.dart';
import 'package:restaurant_app/core/errors/failures.dart';
import 'package:restaurant_app/core/network/api_endpoints.dart';
import 'package:restaurant_app/core/utils/validators.dart';
import 'package:restaurant_app/core/utils/formatters.dart';

class _DummyFailure extends Failure {
  const _DummyFailure() : super('dummy');
}

void main() {
  setUpAll(() async {
    // Pure Dart tests do not auto-initialize locale data; Flutter apps do.
    await initializeDateFormatting('ar');
  });

  group('Validators', () {
    test('isValidEmail accepts valid addresses', () {
      expect(Validators.isValidEmail('a@b.com'), isTrue);
      expect(Validators.isValidEmail('name.last+tag@sub.example.co'), isTrue);
    });

    test('isValidEmail rejects invalid addresses', () {
      expect(Validators.isValidEmail(null), isFalse);
      expect(Validators.isValidEmail(''), isFalse);
      expect(Validators.isValidEmail('plainaddress'), isFalse);
      expect(Validators.isValidEmail('a@b'), isFalse);
      expect(Validators.isValidEmail('a@.com'), isFalse);
    });

    test('isValidPhone accepts Saudi formats', () {
      expect(Validators.isValidPhone('0555555555'), isTrue);
      expect(Validators.isValidPhone('+966555555555'), isTrue);
      expect(Validators.isValidPhone('00966555555555'), isTrue);
      expect(Validators.isValidPhone('05 5555 5555'), isTrue);
    });

    test('isValidPhone rejects invalid numbers', () {
      expect(Validators.isValidPhone(null), isFalse);
      expect(Validators.isValidPhone(''), isFalse);
      expect(Validators.isValidPhone('0455555555'), isFalse);
      expect(Validators.isValidPhone('0555'), isFalse);
    });

    test('isValidOtp accepts six digits only', () {
      expect(Validators.isValidOtp('123456'), isTrue);
      expect(Validators.isValidOtp('12345'), isFalse);
      expect(Validators.isValidOtp('1a3456'), isFalse);
      expect(Validators.isValidOtp(null), isFalse);
    });

    test('isValidName accepts Arabic/Latin names', () {
      expect(Validators.isValidName('أحمد'), isTrue);
      expect(Validators.isValidName('John Doe'), isTrue);
      expect(Validators.isValidName(' '), isFalse);
      expect(Validators.isValidName(null), isFalse);
    });
  });

  group('Formatters', () {
    test('formatCurrency appends Arabic currency symbol', () {
      expect(
        Formatters.formatCurrency(50),
        '50.00 ${AppConfig.defaultCurrency}',
      );
    });

    test('formatDate uses Arabic locale', () {
      final formatted = Formatters.formatDate(DateTime(2026, 8, 6));
      expect(formatted, contains('أغسطس'));
    });

    test('formatTime is 24-hour', () {
      expect(Formatters.formatTime(DateTime(2026, 8, 6, 19, 30)), '19:30');
    });

    test('formatOrderNumber prefixes with #', () {
      expect(Formatters.formatOrderNumber(1024), '#1024');
    });
  });

  group('EnvironmentConfig', () {
    test('baseUrl resolves to dev for current env', () {
      expect(
        EnvironmentConfig.baseUrl,
        'https://dev-api.restaurant.example.com',
      );
    });

    test('wsUrl is derived', () {
      expect(EnvironmentConfig.wsUrl, 'wss://dev-api.restaurant.example.com');
    });
  });

  group('ApiEndpoints', () {
    test('auth endpoints are built on the base URL', () {
      expect(ApiEndpoints.login, contains('/auth/login'));
      expect(ApiEndpoints.verifyOtp, contains('/auth/verify-otp'));
      expect(ApiEndpoints.refreshToken, contains('/auth/refresh'));
      expect(ApiEndpoints.base, EnvironmentConfig.baseUrl);
    });
  });

  group('Either', () {
    test('when maps Left and Right correctly', () {
      const left = Left<Failure, int>(_DummyFailure());
      const right = Right<Failure, int>(42);

      expect(
        left.when(onLeft: (f) => f.message, onRight: (v) => '$v'),
        'dummy',
      );
      expect(right.when(onLeft: (f) => 'err', onRight: (v) => '$v'), '42');
    });
  });
}
