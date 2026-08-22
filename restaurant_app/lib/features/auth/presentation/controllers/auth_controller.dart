import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/app_cache.dart';
import '../../../../core/data/offline_queue_service.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../../orders/presentation/controllers/orders_controller.dart';
import '../../domain/entities/user_entity.dart';

/// Authentication lifecycle status.
enum AuthStatus {
  /// Session state has not been determined yet (e.g. on app launch).
  unknown,

  /// A user is currently authenticated.
  authenticated,

  /// No authenticated user.
  unauthenticated,
}

/// Immutable authentication state exposed to the UI.
class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.authFailure,
  });

  final AuthStatus status;
  final UserEntity? user;
  final Failure? authFailure;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.unknown;

  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    Failure? authFailure,
    bool clearFailure = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      authFailure: clearFailure ? null : (authFailure ?? this.authFailure),
    );
  }
}

/// Controller for authentication state.
///
/// Bridges the domain [LoginUseCase]/[VerifyOtpUseCase]/[LogoutUseCase]/
/// [RefreshTokenUseCase] into the [AuthState] consumed by the UI and the
/// role-based router.
class AuthController extends StateNotifier<AuthState> {
  AuthController(this.ref) : super(const AuthState());

  final Ref ref;

  /// Restores a session on startup: first tries a token refresh, then falls
  /// back to a persisted demo/user profile saved by a prior [login].
  Future<void> bootstrap() async {
    state = const AuthState(status: AuthStatus.unknown);
    final refreshResult = await ref.read(refreshTokenUseCaseProvider).call();
    if (!mounted) return;
    final ok = refreshResult.when(onLeft: (_) => false, onRight: (_) => true);
    if (ok) {
      // A live refresh succeeded; for now we still need a `me` call to get the
      // full profile, which is out of scope offline. Fall through to restore.
    }
    final restoreResult = await ref.read(restoreSessionUseCaseProvider).call();
    if (!mounted) return;
    restoreResult.when(
      onLeft: (_) {
        state = const AuthState(status: AuthStatus.unauthenticated);
      },
      onRight: (user) {
        state = AuthState(status: AuthStatus.authenticated, user: user);
      },
    );
  }

  /// Logs in with an email/phone [identifier] and [password].
  Future<void> login(String identifier, String password) async {
    state = state.copyWith(status: AuthStatus.unknown, clearFailure: true);
    final result = await ref
        .read(loginUseCaseProvider)
        .call(identifier, password);
    if (!mounted) return;
    result.when(
      onLeft: _onFailure,
      onRight: (user) {
        state = AuthState(status: AuthStatus.authenticated, user: user);
      },
    );
  }

  /// Registers a new user with [name], [email], [phone], [password], [restaurantId], and [role].
  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String restaurantId,
    UserRole role = UserRole.customer,
  }) async {
    state = state.copyWith(status: AuthStatus.unknown, clearFailure: true);
    final result = await ref.read(registerUseCaseProvider).call(
          name: name,
          email: email,
          phone: phone,
          password: password,
          restaurantId: restaurantId,
          role: role,
        );
    if (!mounted) return;
    result.when(
      onLeft: _onFailure,
      onRight: (user) {
        state = AuthState(status: AuthStatus.authenticated, user: user);
      },
    );
  }

  /// Verifies the one-time [otp] sent to [phone].
  Future<void> verifyOtp(String otp, String phone) async {
    state = state.copyWith(status: AuthStatus.unknown, clearFailure: true);
    final result = await ref
        .read(verifyOtpUseCaseProvider)
        .call(otp: otp, phone: phone);
    if (!mounted) return;
    result.when(
      onLeft: _onFailure,
      onRight: (user) {
        state = state.copyWith(status: AuthStatus.authenticated, user: user);
      },
    );
  }

  /// Logs out the current user.
  ///
  /// Besides clearing auth credentials (repository), this wipes every local
  /// trace of the previous account: the Hive app cache, the offline operation
  /// queue, and in-memory cart/orders state — so no cross-account data can
  /// ever leak into the next session.
  Future<void> logout() async {
    await ref.read(logoutUseCaseProvider).call();

    // Wipe durable caches (best-effort: logout must always succeed locally).
    try {
      await ref.read(offlineQueueServiceProvider).clear();
      await ref.read(localCacheServiceProvider)?.clear();
    } catch (e) {
      AppLogger.warning('logout: local cache wipe issue: $e');
    }

    if (!mounted) return;
    state = const AuthState(status: AuthStatus.unauthenticated);

    // Reset session-scoped controllers AFTER the auth state flip so UI
    // rebuilds against clean, empty state.
    ref.invalidate(cartControllerProvider);
    ref.invalidate(ordersControllerProvider);
  }

  void _onFailure(Failure failure) {
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      authFailure: failure,
    );
  }
}

/// Provider for [AuthController].
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(ref);
  },
);
