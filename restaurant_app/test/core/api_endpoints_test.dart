import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/network/api_endpoints.dart';

void main() {
  group('ApiEndpoints Unit Tests', () {
    test('resolves endpoints against base URL', () {
      final base = ApiEndpoints.base;
      expect(base, isNotEmpty);
      expect(ApiEndpoints.register, '$base/auth/register');
      expect(ApiEndpoints.login, '$base/auth/login');
      expect(ApiEndpoints.verifyOtp, '$base/auth/verify-otp');
      expect(ApiEndpoints.refreshToken, '$base/auth/refresh');
      expect(ApiEndpoints.me, '$base/auth/me');
      expect(ApiEndpoints.logout, '$base/auth/logout');
      expect(ApiEndpoints.menu, '$base/menu');
      expect(ApiEndpoints.orders, '$base/orders');
      expect(ApiEndpoints.tables, '$base/tables');
    });
  });
}
