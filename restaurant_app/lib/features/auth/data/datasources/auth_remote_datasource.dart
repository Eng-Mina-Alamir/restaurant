import 'package:dio/dio.dart';

import '../../../../config/constants.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/user_model.dart';

/// Contract for the remote auth data source.
///
/// Defines the raw network operations needed by auth without leaking HTTP/Dio
/// details into the repository. Implementations translate transport errors into
/// typed [AppException]s.
abstract class AuthRemoteDataSource {
  /// Authenticates a user with an email/phone [identifier] and [password].
  Future<UserModel> login(String identifier, String password);

  /// Verifies an OTP sent to [phone].
  Future<UserModel> verifyOtp({required String otp, required String phone});

  /// Exchanges [refreshToken] for a new access token, returning the token.
  Future<String> refreshToken(String refreshToken);

  /// Registers a new user account with provided details.
  Future<UserModel> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String restaurantId,
    UserRole role = UserRole.customer,
  });

  /// Ends the session for the given access [token].
  Future<void> logout(String? token);
}

/// Dio-backed implementation of [AuthRemoteDataSource].
///
/// Requests are shaped against [ApiEndpoints] and responses parsed into
/// [UserModel]. Errors are surfaced as typed exceptions for the repository to
/// translate into [Failure]s.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<UserModel> login(String identifier, String password) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.login,
        data: <String, dynamic>{'identifier': identifier, 'password': password},
      );
      return _parseUser(response.data);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  @override
  Future<UserModel> verifyOtp({
    required String otp,
    required String phone,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.verifyOtp,
        data: <String, dynamic>{'otp': otp, 'phone': phone},
      );
      return _parseUser(response.data);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  @override
  Future<String> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.refreshToken,
        data: <String, dynamic>{'refreshToken': refreshToken},
      );
      final data = response.data;
      if (data == null) {
        throw const ServerException(AppConstants.errorInvalidToken);
      }
      final token = data['token'] as String?;
      if (token == null || token.isEmpty) {
        throw const ServerException(AppConstants.errorInvalidToken);
      }
      return token;
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
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
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.login,
        data: <String, dynamic>{
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          // SECURITY: never send a client-chosen role — the server assigns
          // roles (signup defaults to customer; staff roles are provisioned
          // by managers). Sending `role` here was a latent privilege
          // escalation vector.
          'restaurant_id': restaurantId,
        },
      );
      return _parseUser(response.data);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  @override
  Future<void> logout(String? token) async {
    try {
      await _dio.post<dynamic>(ApiEndpoints.logout);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  /// Parses the `user` object (or a flat user map) into a [UserModel].
  UserModel _parseUser(Map<String, dynamic>? payload) {
    final data = payload?['user'] is Map<String, dynamic>
        ? payload!['user']! as Map<String, dynamic>
        : payload;
    if (data == null) {
      throw const ServerException(AppConstants.errorInvalidResponse);
    }
    return UserModel.fromJson(data);
  }

  /// Translates a [DioException] into a typed application exception.
  AppException _mapDioException(DioException error) {
    final statusCode = error.response?.statusCode;
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.unknown) {
      return NetworkException(
        AppConstants.errorNoNetwork,
        statusCode: statusCode,
        type: error.type.name,
      );
    }
    return ServerException(AppConstants.errorServer, statusCode: statusCode);
  }
}
