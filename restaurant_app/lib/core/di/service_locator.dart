import '../../config/environment.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/refresh_token_usecase.dart';
import '../../features/auth/domain/usecases/verify_otp_usecase.dart';
import '../network/dio_client.dart';
import '../storage/secure_storage_service.dart';

/// Manual dependency locator used before full Riverpod wiring is in place.
///
/// Cleanup note: Task 5 will replace this with Riverpod providers (see
/// `service_locator` Riverpod plan). Until then this composes the auth stack
/// with lazily-initialized singletons.
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
  static VerifyOtpUseCase get verifyOtpUseCase =>
      VerifyOtpUseCase(authRepository);
  static LogoutUseCase get logoutUseCase => LogoutUseCase(authRepository);
  static RefreshTokenUseCase get refreshTokenUseCase =>
      RefreshTokenUseCase(authRepository);
}
