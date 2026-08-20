import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/config/constants.dart';
import 'package:restaurant_app/core/errors/failures.dart';

void main() {
  group('Failures Tests', () {
    test('NetworkFailure has default message and custom message', () {
      const defaultFailure = NetworkFailure();
      expect(defaultFailure.message, AppConstants.errorConnection);
      expect(defaultFailure.toString(), contains('NetworkFailure'));

      const customFailure = NetworkFailure('No internet');
      expect(customFailure.message, 'No internet');
    });

    test('ServerFailure has default and custom message with statusCode', () {
      const defaultFailure = ServerFailure();
      expect(defaultFailure.message, AppConstants.errorServer);
      expect(defaultFailure.statusCode, isNull);

      const customFailure = ServerFailure('Custom server error', 500);
      expect(customFailure.message, 'Custom server error');
      expect(customFailure.statusCode, 500);
    });

    test('ValidationFailure has default and custom message', () {
      const defaultFailure = ValidationFailure();
      expect(defaultFailure.message, AppConstants.errorGeneric);

      const customFailure = ValidationFailure('Invalid email');
      expect(customFailure.message, 'Invalid email');
    });

    test('NotFoundFailure has default message and custom message', () {
      const defaultFailure = NotFoundFailure();
      expect(defaultFailure.message, 'العنصر غير موجود');

      const customFailure = NotFoundFailure('User not found');
      expect(customFailure.message, 'User not found');
    });

    test('CacheFailure has default and custom message', () {
      const defaultFailure = CacheFailure();
      expect(defaultFailure.message, AppConstants.errorCache);

      const customFailure = CacheFailure('Storage error');
      expect(customFailure.message, 'Storage error');
    });

    test('UnauthorizedFailure has default and custom message', () {
      const defaultFailure = UnauthorizedFailure();
      expect(defaultFailure.message, AppConstants.errorSessionExpired);

      const customFailure = UnauthorizedFailure('Invalid token');
      expect(customFailure.message, 'Invalid token');
    });

    test('Failure factory constructors produce correct types', () {
      const f1 = Failure.validation('Invalid');
      expect(f1, isA<ValidationFailure>());
      expect(f1.message, 'Invalid');

      const f2 = Failure.server('Server 500', 500);
      expect(f2, isA<ServerFailure>());
      expect((f2 as ServerFailure).statusCode, 500);

      const f3 = Failure.network('Disconnected');
      expect(f3, isA<NetworkFailure>());

      const f4 = Failure.cache('Disk full');
      expect(f4, isA<CacheFailure>());

      const f5 = Failure.unauthorized('Denied');
      expect(f5, isA<UnauthorizedFailure>());

      const f6 = Failure.notFound('Missing');
      expect(f6, isA<NotFoundFailure>());
    });
  });
}
