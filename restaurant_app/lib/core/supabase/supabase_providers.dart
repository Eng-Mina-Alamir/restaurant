import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/supabase_config.dart';

/// Exposes the global initialized [SupabaseClient] with safe fallback for tests.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  try {
    return Supabase.instance.client;
  } catch (_) {
    // In widget tests or standalone unit test environments where Supabase.initialize
    // hasn't been invoked, construct a client instance safely with autoRefreshToken disabled.
    final url = SupabaseConfig.url.isNotEmpty
        ? SupabaseConfig.url
        : 'https://placeholder.supabase.co';
    final anon = SupabaseConfig.anonKey.isNotEmpty
        ? SupabaseConfig.anonKey
        : 'placeholder-anon-key';
    return SupabaseClient(
      url,
      anon,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
  }
});

/// Exposes the Supabase [GoTrueClient] for authentication.
final supabaseAuthProvider = Provider<GoTrueClient>((ref) {
  return ref.watch(supabaseClientProvider).auth;
});

/// Stream of auth state changes from Supabase (sign in, sign out, token refresh).
final supabaseAuthStateProvider = StreamProvider<AuthState>((ref) {
  try {
    final supabase = ref.watch(supabaseClientProvider);
    return supabase.auth.onAuthStateChange;
  } catch (_) {
    return const Stream.empty();
  }
});

/// Exposes the current authenticated Supabase [User], or null if not logged in.
final supabaseCurrentUserProvider = Provider<User?>((ref) {
  try {
    final authState = ref.watch(supabaseAuthStateProvider);
    return authState.value?.session?.user ??
        ref.watch(supabaseClientProvider).auth.currentUser;
  } catch (_) {
    return null;
  }
});
