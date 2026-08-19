import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_config.dart';
import '../../config/environment.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/datasources/demo_auth_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/refresh_token_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/domain/usecases/restore_session_usecase.dart';
import '../../features/auth/domain/usecases/verify_otp_usecase.dart';
import '../../features/menu/data/repositories/menu_repository_impl.dart';
import '../../features/menu/domain/repositories/menu_repository.dart';
import '../network/dio_client.dart';
import '../storage/in_memory_secure_storage_service.dart';
import '../storage/secure_storage_service.dart';

/// Manual dependency locator used before full Riverpod wiring is in place.
///
/// Note: This class provides lazily-initialized singletons. The Riverpod
/// providers below (`*Provider`s) are the preferred dependency-injection
/// mechanism for feature code; this class remains for legacy/utility call
/// sites until they are migrated.
class ServiceLocator {
  ServiceLocator._();

  /// FlutterSecureStorage-backed, shared across the app.
  static const SecureStorageService _secureStorage = SecureStorageService();

  static SecureStorageService get secureStorage => _secureStorage;

  /// Configured Dio client bound to the active environment's base URL.
  static final DioClient _dioClient = DioClient(
    baseUrl: EnvironmentConfig.baseUrl,
    storage: _secureStorage,
  );

  static DioClient get dioClient => _dioClient;

  static final AuthRemoteDataSource _remoteDataSource =
      AuthRemoteDataSourceImpl(_dioClient.dio);

  static AuthRemoteDataSource get remoteDataSource => _remoteDataSource;

  static final AuthRepository _authRepository = AuthRepositoryImpl(
    remoteDataSource: _remoteDataSource,
    secureStorage: _secureStorage,
  );
  static AuthRepository get authRepository => _authRepository;

  // ── Auth use cases ────────────────────────────────────────────────────────

  static LoginUseCase get loginUseCase => LoginUseCase(authRepository);
  static RegisterUseCase get registerUseCase => RegisterUseCase(authRepository);
  static VerifyOtpUseCase get verifyOtpUseCase =>
      VerifyOtpUseCase(authRepository);
  static LogoutUseCase get logoutUseCase => LogoutUseCase(authRepository);
  static RefreshTokenUseCase get refreshTokenUseCase =>
      RefreshTokenUseCase(authRepository);
  static RestoreSessionUseCase get restoreSessionUseCase =>
      RestoreSessionUseCase(authRepository);
}

// ── Riverpod providers ─────────────────────────────────────────────────────────

/// Single shared instance of the secure storage service.
///
/// Demo mode uses an in-memory store (no platform keystore dependency); real
/// builds use the platform secure storage.
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  if (AppConfig.useDemoAuth) return InMemorySecureStorageService();
  return ServiceLocator.secureStorage;
});

/// Dio client configured for the active environment.
final dioClientProvider = Provider<DioClient>((ref) {
  return ServiceLocator.dioClient;
});

/// Remote auth data source.
///
/// In demo mode uses the offline [DemoAuthRemoteDataSource] so every role
/// can be explored without a backend; otherwise uses the Dio-backed client.
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  if (AppConfig.useDemoAuth) return DemoAuthRemoteDataSource();
  return AuthRemoteDataSourceImpl(ref.watch(dioClientProvider).dio);
});

/// Auth repository combining the remote data source with secure storage.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    secureStorage: ref.watch(secureStorageServiceProvider),
  );
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return RegisterUseCase(ref.watch(authRepositoryProvider));
});

final verifyOtpUseCaseProvider = Provider<VerifyOtpUseCase>((ref) {
  return VerifyOtpUseCase(ref.watch(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.watch(authRepositoryProvider));
});

final refreshTokenUseCaseProvider = Provider<RefreshTokenUseCase>((ref) {
  return RefreshTokenUseCase(ref.watch(authRepositoryProvider));
});

final restoreSessionUseCaseProvider = Provider<RestoreSessionUseCase>((ref) {
  return RestoreSessionUseCase(ref.watch(authRepositoryProvider));
});

// ── Menu ───────────────────────────────────────────────────────────────────────

final _sharedMenuRepository = MenuRepositoryImpl();

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  return _sharedMenuRepository;
});

