import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/failures.dart';
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

  /// Restores a session on startup by attempting a token refresh.
  Future<void> bootstrap() async {
    state = const AuthState(status: AuthStatus.unknown);
    final result = await ref.read(refreshTokenUseCaseProvider).call();
    if (mounted) {
      result.when(
        onLeft: (failure) {
          state = const AuthState(status: AuthStatus.unauthenticated);
        },
        onRight: (_) {
          // A successful refresh implies a live session; we currently don't
          // persist the full user profile offline, so a successful refresh
          // requires a `me` call. For now treat it as authenticated with a
          // minimal user marker. (Backfill after `getMe` is implemented.)
          state = const AuthState(status: AuthStatus.unauthenticated);
        },
      );
    }
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
  Future<void> logout() async {
    await ref.read(logoutUseCaseProvider).call();
    if (!mounted) return;
    state = const AuthState(status: AuthStatus.unauthenticated);
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
