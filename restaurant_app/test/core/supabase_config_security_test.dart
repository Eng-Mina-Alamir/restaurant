import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/config/supabase_config.dart';

void main() {
  group('Supabase Configuration Security & Schema Tests', () {
    test('Supabase URL is valid HTTPS endpoint', () {
      if (SupabaseConfig.isConfigured) {
        expect(SupabaseConfig.url, isNotEmpty);
        expect(SupabaseConfig.url, startsWith('https://'));
        final uri = Uri.tryParse(SupabaseConfig.url);
        expect(uri, isNotNull);
        expect(uri?.host, contains('supabase.co'));
      } else {
        expect(SupabaseConfig.isConfigured, isFalse);
      }
    });

    test('Supabase Anon Key is configured properly', () {
      if (SupabaseConfig.isConfigured) {
        expect(SupabaseConfig.anonKey, isNotEmpty);
        expect(SupabaseConfig.anonKey.length, greaterThan(20));
      } else {
        expect(SupabaseConfig.isConfigured, isFalse);
      }
    });

    test('Supabase table name constants match schema tables', () {
      expect(SupabaseConfig.profilesTable, 'profiles');
      expect(SupabaseConfig.categoriesTable, 'categories');
      expect(SupabaseConfig.menuItemsTable, 'menu_items');
      expect(SupabaseConfig.modifierGroupsTable, 'menu_modifier_groups');
      expect(SupabaseConfig.modifierOptionsTable, 'menu_modifier_options');
      expect(SupabaseConfig.tablesTable, 'tables');
      expect(SupabaseConfig.ordersTable, 'orders');
      expect(SupabaseConfig.orderItemsTable, 'order_items');
      expect(SupabaseConfig.reservationsTable, 'reservations');
      expect(SupabaseConfig.couponsTable, 'coupons');
      expect(SupabaseConfig.ratingsTable, 'ratings');
      expect(SupabaseConfig.inventoryTable, 'inventory');
      expect(SupabaseConfig.driverLocationsTable, 'driver_locations');
    });

    test('Supabase storage buckets match storage configuration', () {
      expect(SupabaseConfig.menuBucket, 'menu-images');
      expect(SupabaseConfig.avatarsBucket, 'user-avatars');
      expect(SupabaseConfig.deliveryProofBucket, 'delivery-proofs');
    });
  });

  group('RLS Guard — every public table must have RLS enabled', () {
    late String schemaSql;

    setUpAll(() {
      final file = File('supabase_schema.sql');
      if (!file.existsSync()) {
        fail(
          'supabase_schema.sql not found at project root. '
          'This guard test must run from the project root directory.',
        );
      }
      schemaSql = file.readAsStringSync();
    });

    test('supabase_schema.sql is non-empty', () {
      expect(schemaSql.trim(), isNotEmpty);
    });

    test('every CREATE TABLE in public schema has ENABLE ROW LEVEL SECURITY', () {
      // Extract all table names from CREATE TABLE statements.
      final createTableRegex = RegExp(
        r'CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?public\.(\w+)',
        caseSensitive: false,
      );
      final rlsRegex = RegExp(
        r'ALTER\s+TABLE\s+public\.(\w+)\s+ENABLE\s+ROW\s+LEVEL\s+SECURITY',
        caseSensitive: false,
      );

      final definedTables = createTableRegex
          .allMatches(schemaSql)
          .map((m) => m.group(1)!)
          .toSet();
      final rlsEnabledTables = rlsRegex
          .allMatches(schemaSql)
          .map((m) => m.group(1)!)
          .toSet();

      expect(
        definedTables,
        isNotEmpty,
        reason: 'No CREATE TABLE statements found — is the schema empty?',
      );

      final unprotected = definedTables.difference(rlsEnabledTables);
      expect(
        unprotected,
        isEmpty,
        reason:
            'The following tables are missing ENABLE ROW LEVEL SECURITY: '
            '${unprotected.join(', ')}. '
            'Every public table MUST have RLS enabled to prevent unauthenticated access.',
      );
    });

    test('helper functions are defined before policies', () {
      // Ensures app_role() and has_role() exist — policies depend on them.
      expect(
        schemaSql,
        contains('CREATE OR REPLACE FUNCTION public.app_role()'),
        reason: 'Missing app_role() helper function',
      );
      expect(
        schemaSql,
        contains('CREATE OR REPLACE FUNCTION public.has_role('),
        reason: 'Missing has_role() helper function',
      );
      expect(
        schemaSql,
        contains('CREATE OR REPLACE FUNCTION public.is_manager_or_admin()'),
        reason: 'Missing is_manager_or_admin() helper function',
      );
    });

    test('anon role cannot call helper functions', () {
      expect(
        schemaSql,
        contains('REVOKE EXECUTE ON FUNCTION public.app_role() FROM anon'),
        reason: 'app_role() must be revoked from anon role',
      );
      expect(
        schemaSql,
        contains(
          'REVOKE EXECUTE ON FUNCTION public.has_role(TEXT[]) FROM anon',
        ),
        reason: 'has_role() must be revoked from anon role',
      );
    });

    test('privilege-escalation trigger exists on profiles', () {
      expect(
        schemaSql,
        contains('trg_protect_profile_privileges'),
        reason:
            'Missing profile privilege-escalation guard trigger. '
            'Self-signup must always downgrade role to customer.',
      );
    });
  });
}
