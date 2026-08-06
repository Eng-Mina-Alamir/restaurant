import '../../../../core/errors/exceptions.dart';
import '../../../../core/domain/enums.dart';
import '../models/user_model.dart';
import 'auth_remote_datasource.dart';

/// Offline demo implementation of [AuthRemoteDataSource].
///
/// Lets reviewers explore every role without a live backend: well-known demo
/// accounts authenticate locally and return a seeded [UserModel]. Real network
/// calls (refresh/logout) fail gracefully with a network-ish exception.
///
/// Use only for development/demo builds; swap via `authRemoteDataSourceProvider`.
abstract final class DemoAuthDataSource {
  static const String password = '123456';

  /// Demo accounts by login role (identifier maps directly to a [UserRole]).
  static const Map<UserRole, String> accounts = {
    UserRole.customer: 'customer@demo.com',
    UserRole.waiter: 'waiter@demo.com',
    UserRole.kitchen: 'kitchen@demo.com',
    UserRole.manager: 'manager@demo.com',
    UserRole.admin: 'admin@demo.com',
    UserRole.driver: 'driver@demo.com',
  };

  /// The login identifiers users type in (routed to the matching role).
  static const List<UserRole> supportedRoles = [
    UserRole.customer,
    UserRole.waiter,
    UserRole.kitchen,
    UserRole.manager,
    UserRole.admin,
    UserRole.driver,
  ];

  /// Returns the demo user for [identifier] when credentials match, else null.
  static UserModel? authenticate(String identifier, String password) {
    if (password != DemoAuthDataSource.password) return null;
    for (final entry in accounts.entries) {
      if (entry.value.toLowerCase() == identifier.trim().toLowerCase()) {
        return _userFor(entry.key);
      }
    }
    return null;
  }

  static UserModel _userFor(UserRole role) {
    final email = accounts[role]!;
    final label = _roleLabel(role);
    return UserModel(
      id: 'demo-${role.name}',
      name: label,
      email: email,
      phone: '0500000000',
      role: role,
      restaurantId: 'demo-restaurant-1',
      token: 'demo-token-${role.name}',
      createdAt: DateTime(2024),
      isActive: true,
    );
  }

  static String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return 'زبون تجريبي';
      case UserRole.waiter:
        return 'نادل تجريبي';
      case UserRole.kitchen:
        return 'مطبخ تجريبي';
      case UserRole.manager:
        return 'مدير تجريبي';
      case UserRole.admin:
        return 'مسؤول تجريبي';
      case UserRole.driver:
        return 'سائق تجريبي';
    }
  }
}

/// [AuthRemoteDataSource] that only handles demo logins.
class DemoAuthRemoteDataSource implements AuthRemoteDataSource {
  @override
  Future<UserModel> login(String identifier, String password) async {
    final user = DemoAuthDataSource.authenticate(identifier, password);
    if (user == null) {
      throw const ServerException('بيانات دخول غير صحيحة');
    }
    return user;
  }

  @override
  Future<UserModel> verifyOtp({
    required String otp,
    required String phone,
  }) async {
    throw const NetworkException('غير متاح في وضع العرض');
  }

  @override
  Future<String> refreshToken(String refreshToken) async {
    throw const NetworkException('غير متاح في وضع العرض');
  }

  @override
  Future<void> logout(String? token) async {}
}
