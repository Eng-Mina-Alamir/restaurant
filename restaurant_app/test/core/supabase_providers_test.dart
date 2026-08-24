import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/supabase/supabase_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('Supabase Providers Unit Tests', () {
    test(
      'supabaseClientProvider produces a non-null SupabaseClient instance',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final client = container.read(supabaseClientProvider);
        expect(client, isA<SupabaseClient>());
      },
    );

    test('supabaseAuthProvider produces GoTrueClient', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final auth = container.read(supabaseAuthProvider);
      expect(auth, isA<GoTrueClient>());
    });

    test(
      'supabaseCurrentUserProvider returns null when no session is active',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final user = container.read(supabaseCurrentUserProvider);
        expect(user, isNull);
      },
    );

    test('supabaseAuthStateProvider exposes a broadcast stream', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final authStateAsync = container.read(supabaseAuthStateProvider);
      expect(authStateAsync, isNotNull);
    });
  });
}
