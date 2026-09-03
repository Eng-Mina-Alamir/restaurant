import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_config.dart';
import '../../config/environment.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/datasources/demo_auth_datasource.dart';
import '../../features/auth/data/datasources/supabase_auth_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/refresh_token_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/domain/usecases/restore_session_usecase.dart';
import '../../features/auth/domain/usecases/verify_otp_usecase.dart';
import '../../features/menu/data/repositories/menu_repository_impl.dart';
import '../../features/menu/data/repositories/supabase_menu_repository.dart';
import '../../features/menu/domain/repositories/menu_repository.dart';
import '../data/app_cache.dart';
import '../network/dio_client.dart';
import '../storage/in_memory_secure_storage_service.dart';
import '../storage/secure_storage_service.dart';
import '../supabase/supabase_providers.dart';
import '../supabase/supabase_storage_service.dart';

export '../supabase/supabase_realtime_service.dart'
    show supabaseRealtimeServiceProvider;

/// Manual dependency locator used across the application.
class ServiceLocator {
  ServiceLocator._();

  static const SecureStorageService _secureStorage = SecureStorageService();

  static SecureStorageService get secureStorage => _secureStorage;

  static final DioClient _dioClient = DioClient(
    baseUrl: EnvironmentConfig.baseUrl,
    storage: _secureStorage,
  );

  static DioClient get dioClient => _dioClient;
}

// ── Riverpod providers ─────────────────────────────────────────────────────────

/// Single shared instance of the secure storage service.
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
/// If demo auth is requested, uses [DemoAuthRemoteDataSource].
/// If Supabase is enabled, uses [SupabaseAuthRemoteDataSourceImpl].
/// Otherwise falls back to Dio client.
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  if (AppConfig.useDemoAuth) return DemoAuthRemoteDataSource();
  if (AppConfig.useSupabase) {
    return SupabaseAuthRemoteDataSourceImpl(ref.watch(supabaseClientProvider));
  }
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

final _fallbackMenuRepository = MenuRepositoryImpl();

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  if (AppConfig.useSupabase) {
    return SupabaseMenuRepositoryImpl(
      ref.watch(supabaseClientProvider),
      ref.watch(localCacheServiceProvider),
    );
  }
  return _fallbackMenuRepository;
});

// ── Supabase Additional Services ──────────────────────────────────────────────

final supabaseStorageServiceProvider = Provider<SupabaseStorageService>((ref) {
  return SupabaseStorageService(ref.watch(supabaseClientProvider));
});
