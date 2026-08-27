import '../../../../config/constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/domain/enums.dart';
import '../models/user_model.dart';
import 'auth_remote_datasource.dart';

/// Offline demo implementation of [AuthRemoteDataSource] with authentic Egyptian roles & accounts.
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
    UserRole.cashier: 'cashier@demo.com',
  };

  /// The login identifiers users type in (routed to the matching role).
  static const List<UserRole> supportedRoles = [
    UserRole.customer,
    UserRole.waiter,
    UserRole.kitchen,
    UserRole.manager,
    UserRole.admin,
    UserRole.driver,
    UserRole.cashier,
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
    final phone = _rolePhone(role);
    return UserModel(
      id: 'demo-${role.name}',
      name: label,
      email: email,
      phone: phone,
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
        return 'أحمد السيد (عميل المحروسة)';
      case UserRole.waiter:
        return 'مينا الأمير (كابتن صالة)';
      case UserRole.kitchen:
        return 'الشيف محمود الشناوي (رئيس المطبخ)';
      case UserRole.manager:
        return 'م. كيرلس الأمير (مدير المطعم)';
      case UserRole.admin:
        return 'إدارة سلسلة مطاعم المحروسة';
      case UserRole.driver:
        return 'الكابتن طارق الدسوقي (مندوب التوصيل)';
      case UserRole.cashier:
        return 'حسام علي (كاشير النقطة)';
    }
  }

  static String _rolePhone(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return '01012345678';
      case UserRole.waiter:
        return '01234567890';
      case UserRole.kitchen:
        return '01122334455';
      case UserRole.manager:
        return '01098765432';
      case UserRole.admin:
        return '01555555555';
      case UserRole.driver:
        return '01066778899';
      case UserRole.cashier:
        return '01044332211';
    }
  }
}

/// [AuthRemoteDataSource] that only handles demo logins.
class DemoAuthRemoteDataSource implements AuthRemoteDataSource {
  @override
  Future<UserModel> login(String identifier, String password) async {
    final user = DemoAuthDataSource.authenticate(identifier, password);
    if (user == null) {
      throw const ServerException(AppConstants.errorInvalidCredentials);
    }
    return user;
  }

  @override
  Future<UserModel> verifyOtp({
    required String otp,
    required String phone,
  }) async {
    throw const NetworkException(AppConstants.errorDemoUnavailable);
  }

  @override
  Future<String> refreshToken(String refreshToken) async {
    throw const NetworkException(AppConstants.errorDemoUnavailable);
  }

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String restaurantId,
    UserRole role = UserRole.customer,
  }) async {
    return UserModel(
      id: 'demo-user-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      phone: phone,
      role: role,
      restaurantId: restaurantId,
      token: 'demo-token-reg-${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      isActive: true,
    );
  }

  @override
  Future<void> logout(String? token) async {}
}
