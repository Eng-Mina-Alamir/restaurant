import 'dart:convert';

import '../../../../core/errors/either.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

/// Concrete [AuthRepository] that composes the remote data source with secure
/// storage.
///
/// Remote exceptions are caught at this boundary and translated into typed
/// [Failure]s exposed to the domain via [Either].
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required SecureStorageService secureStorage,
  }) : _remoteDataSource = remoteDataSource,
       _secureStorage = secureStorage;

  final AuthRemoteDataSource _remoteDataSource;
  final SecureStorageService _secureStorage;

  @override
  Future<Either<Failure, UserEntity>> login(
    String identifier,
    String password,
  ) async {
    try {
      final model = await _remoteDataSource.login(identifier, password);
      await _persistToken(model.token);
      await _persistSession(model);
      return Right<Failure, UserEntity>(model.toEntity());
    } on AppException catch (error) {
      return Left<Failure, UserEntity>(_toFailure(error));
    } catch (_) {
      return const Left<Failure, UserEntity>(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> verifyOtp({
    required String otp,
    required String phone,
  }) async {
    try {
      final model = await _remoteDataSource.verifyOtp(otp: otp, phone: phone);
      await _persistToken(model.token);
      return Right<Failure, UserEntity>(model.toEntity());
    } on AppException catch (error) {
      return Left<Failure, UserEntity>(_toFailure(error));
    } catch (_) {
      return const Left<Failure, UserEntity>(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, String>> refreshToken() async {
    try {
      final storedRefresh = await _secureStorage.readRefreshToken();
      if (storedRefresh == null || storedRefresh.isEmpty) {
        return const Left<Failure, String>(UnauthorizedFailure());
      }
      final newToken = await _remoteDataSource.refreshToken(storedRefresh);
      await _secureStorage.writeToken(newToken);
      return Right<Failure, String>(newToken);
    } on AppException catch (error) {
      return Left<Failure, String>(_toFailure(error));
    } catch (_) {
      return const Left<Failure, String>(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> restoreSession() async {
    try {
      final stored = await _secureStorage.read(_sessionKey);
      if (stored == null || stored.isEmpty) {
        return const Left<Failure, UserEntity>(UnauthorizedFailure());
      }
      final model = UserModel.fromJson(
        jsonDecode(stored) as Map<String, dynamic>,
      );
      return Right<Failure, UserEntity>(model.toEntity());
    } on AppException catch (error) {
      return Left<Failure, UserEntity>(_toFailure(error));
    } catch (_) {
      return const Left<Failure, UserEntity>(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      final token = await _secureStorage.readToken();
      await _remoteDataSource.logout(token);
      await _secureStorage.deleteToken();
      await _secureStorage.deleteRefreshToken();
      await _secureStorage.delete(_sessionKey);
      return const Right<Failure, void>(null);
    } on AppException catch (error) {
      // Even if the remote call fails we still want a clean local session.
      await _secureStorage.deleteToken();
      await _secureStorage.deleteRefreshToken();
      await _secureStorage.delete(_sessionKey);
      return Left<Failure, void>(_toFailure(error));
    } catch (_) {
      await _secureStorage.deleteToken();
      await _secureStorage.deleteRefreshToken();
      await _secureStorage.delete(_sessionKey);
      return const Right<Failure, void>(null);
    }
  }

  /// Persists an access token (and clears any stale refresh token) to storage.
  Future<void> _persistToken(String? token) async {
    if (token != null && token.isNotEmpty) {
      await _secureStorage.writeToken(token);
    }
  }

  /// Persists the full user profile so [restoreSession] can revive the session
  /// offline (demo mode) without a `getMe` call.
  Future<void> _persistSession(UserModel model) async {
    await _secureStorage.write(
      key: _sessionKey,
      value: jsonEncode(model.toJson()),
    );
  }

  static const String _sessionKey = 'demo_user_session';

  /// Maps an [AppException] to the corresponding domain [Failure].
  Failure _toFailure(AppException error) {
    if (error is NetworkException) {
      return NetworkFailure(error.message);
    }
    if (error is ServerException) {
      return ServerFailure(error.message, error.statusCode);
    }
    if (error is InvalidCredentialsException) {
      return ValidationFailure(error.message);
    }
    return ServerFailure(error.message);
  }
}
