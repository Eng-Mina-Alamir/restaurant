import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static security guard: fails the suite if any table in `supabase_schema.sql`
/// or `supabase_migration_v3.sql` drifts away from its RLS hardening contract:
/// every created table must keep a matching `ENABLE ROW LEVEL SECURITY`
/// statement, audit-trail inserts must stay driver-proof and self-bound
/// (`changed_by = auth.uid()`), and migration policies must stay re-runnable.
///
/// This keeps the deny-by-default guarantee enforced by CI instead of trust.
void main() {
  final schema = _loadSqlFile('supabase_schema.sql');
  final migrationV3 = _loadSqlFile('supabase_migration_v3.sql');
  final migrationV4 = _loadSqlFile('supabase_migration_v4.sql');

  group('Supabase schema RLS hardening guard', () {
    final createdTables = RegExp(
      r'CREATE TABLE IF NOT EXISTS public\.([a-z_]+)',
      caseSensitive: false,
    ).allMatches(schema).map((m) => m.group(1)!).toSet();

    final rlsEnabledTables = RegExp(
      r'ALTER TABLE\s+(?:ONLY\s+)?public\.([a-z_]+)\s+ENABLE ROW LEVEL SECURITY',
      caseSensitive: false,
    ).allMatches(schema).map((m) => m.group(1)!).toSet();

    test('schema file exists and declares tables', () {
      expect(schema, isNotEmpty);
      expect(createdTables, isNotEmpty);
    });

    test('every created table has ENABLE ROW LEVEL SECURITY', () {
      final unprotected = createdTables.difference(rlsEnabledTables).toList()
        ..sort();
      expect(
        unprotected,
        isEmpty,
        reason:
            'Tables without RLS are publicly readable/writable via the '
            'anon key: $unprotected — add ENABLE ROW LEVEL SECURITY and '
            'explicit policies.',
      );
      // Sanity: the regexes actually matched real content.
      expect(rlsEnabledTables.length, greaterThanOrEqualTo(17));
    });

    test('no permissive catch-all policies exist', () {
      // A policy with USING (true) is only acceptable on public catalog
      // SELECT paths; it must never appear on write operations.
      final writePolicyWithTrue = RegExp(
        r'CREATE POLICY\s+\w+\s+ON\s+public\.\w+\s+FOR\s+(INSERT|UPDATE|DELETE)\b[^;]*USING\s*\(\s*true\s*\)',
        caseSensitive: false,
      );
      expect(writePolicyWithTrue.hasMatch(schema), isFalse);
    });

    test('server-side role helpers exist', () {
      for (final fn in [
        'app_role',
        'has_role',
        'is_staff',
        'is_manager_or_admin',
      ]) {
        expect(
          schema.contains('FUNCTION public.$fn'),
          isTrue,
          reason: 'Missing role-resolution helper public.$fn',
        );
      }
    });

    test('privilege-escalation guard triggers exist', () {
      expect(
        schema.contains('trg_protect_profile_privileges'),
        isTrue,
        reason: 'profiles.role must be protected against self-escalation',
      );
      expect(
        schema.contains('trg_restrict_coupon_updates'),
        isTrue,
        reason: 'Coupon redemption must only be able to bump usage_count',
      );
    });
  });

  group('order_status_log audit-trail insert hardening', () {
    const expectedGuard =
        "WITH CHECK (public.has_role(ARRAY['waiter','kitchen','cashier','manager','admin']::TEXT[])"
        ' AND changed_by = auth.uid())';

    for (final entry in <String, String>{
      'supabase_schema.sql': schema,
      'supabase_migration_v3.sql': migrationV3,
    }.entries) {
      final normalized = entry.value.replaceAll(RegExp(r'\s+'), ' ');

      test('${entry.key}: insert policy binds changed_by = auth.uid()', () {
        expect(
          normalized.contains(expectedGuard),
          isTrue,
          reason:
              'order_status_log_insert must require changed_by = auth.uid() '
              'and grant via an explicit non-driver role list',
        );
      });

      test(
        '${entry.key}: insert policy does NOT grant via plain is_staff()',
        () {
          final policyMatch = RegExp(
            r'CREATE POLICY order_status_log_insert\b[^;]*;',
            caseSensitive: false,
          ).firstMatch(normalized);
          expect(policyMatch, isNotNull);
          expect(
            policyMatch!.group(0),
            isNot(contains('is_staff()')),
            reason:
                'is_staff() includes the driver role — a driver could forge '
                'audit rows for ANY order if it gates order_status_log inserts',
          );
        },
      );
    }
  });

  group('migration v3 idempotency guard', () {
    test('every CREATE POLICY is preceded by DROP POLICY IF EXISTS', () {
      final creates = RegExp(
        r'CREATE POLICY (\w+) ON public\.(\w+)\b',
        caseSensitive: false,
      ).allMatches(migrationV3).toList();

      expect(creates, isNotEmpty);

      for (final create in creates) {
        final policyName = create.group(1)!;
        final table = create.group(2)!;
        final drop = RegExp(
          'DROP POLICY IF EXISTS $policyName ON public\\.$table\\s*;',
          caseSensitive: false,
        ).firstMatch(migrationV3);

        expect(
          drop,
          isNotNull,
          reason:
              'CREATE POLICY $policyName has no re-run guard; bare CREATE '
              'POLICY fails on a second migration run',
        );
        expect(
          drop!.start,
          lessThan(create.start),
          reason:
              'DROP POLICY IF EXISTS $policyName must precede its CREATE POLICY',
        );
      }

      final dropCount = RegExp(
        r'DROP POLICY IF EXISTS \w+ ON public\.',
        caseSensitive: false,
      ).allMatches(migrationV3).length;
      expect(
        dropCount,
        equals(creates.length),
        reason: 'Every CREATE POLICY needs exactly one matching guard',
      );
    });

    test(
      'migration v3 keeps shared policies statement-identical to schema',
      () {
        String normalize(String sql) => sql.replaceAll(RegExp(r'\s+'), ' ');
        String extractInsertPolicy(String sql) => normalize(
          sql,
        ).split('CREATE POLICY order_status_log_insert ').last.split(';').first;

        expect(
          extractInsertPolicy(migrationV3),
          equals(extractInsertPolicy(schema)),
          reason: 'order_status_log_insert must be identical in both SQL files',
        );
      },
    );
  });

  group('migration v4 (chat) guard', () {
    final normalizedSchema = schema.replaceAll(RegExp(r'\s+'), ' ');
    final normalizedV4 = migrationV4.replaceAll(RegExp(r'\s+'), ' ');

    test('chat_messages table exists in both files', () {
      expect(
        normalizedSchema.contains(
          'CREATE TABLE IF NOT EXISTS public.chat_messages',
        ),
        isTrue,
      );
      expect(
        normalizedV4.contains(
          'CREATE TABLE IF NOT EXISTS public.chat_messages',
        ),
        isTrue,
      );
    });

    test('chat RLS binds sender_id = auth.uid() on INSERT in both files', () {
      for (final entry in <String, String>{
        'supabase_schema.sql': normalizedSchema,
        'supabase_migration_v4.sql': normalizedV4,
      }.entries) {
        final insertMatch = RegExp(
          r'CREATE POLICY chat_messages_insert\b[^;]*;',
          caseSensitive: false,
        ).firstMatch(entry.value);
        expect(insertMatch, isNotNull, reason: entry.key);
        expect(
          insertMatch!.group(0),
          contains('sender_id = auth.uid()'),
          reason: '${entry.key}: chat inserts must be authored by the caller',
        );
        // Participant gate must reference BOTH participant paths.
        expect(
          insertMatch.group(0),
          contains('o.customer_id = auth.uid()'),
          reason: entry.key,
        );
        expect(
          insertMatch.group(0),
          contains('da.driver_id = auth.uid()'),
          reason: entry.key,
        );
      }
    });

    test('migration v4 keeps policies statement-identical to schema', () {
      String normalize(String sql) => sql.replaceAll(RegExp(r'\s+'), ' ');
      String policyOf(String sql, String name) =>
          normalize(sql).split('CREATE POLICY $name ').last.split(';').first;

      expect(
        policyOf(migrationV4, 'chat_messages_select'),
        equals(policyOf(schema, 'chat_messages_select')),
      );
      expect(
        policyOf(migrationV4, 'chat_messages_insert'),
        equals(policyOf(schema, 'chat_messages_insert')),
      );
    });

    test('every v4 CREATE POLICY is preceded by DROP POLICY IF EXISTS', () {
      final creates = RegExp(
        r'CREATE POLICY (\w+) ON public\.(\w+)\b',
        caseSensitive: false,
      ).allMatches(migrationV4).toList();

      expect(creates, isNotEmpty);
      for (final create in creates) {
        final drop = RegExp(
          'DROP POLICY IF EXISTS ${create.group(1)!} ON public\\.${create.group(2)!}\\s*;',
          caseSensitive: false,
        ).firstMatch(migrationV4);
        expect(drop, isNotNull);
        expect(drop!.start, lessThan(create.start));
      }
    });
  });
}

String _loadSqlFile(String fileName) {
  for (final prefix in const ['', '../']) {
    final file = File('$prefix$fileName');
    if (file.existsSync()) return file.readAsStringSync();
  }
  fail('$fileName not found relative to test working directory');
}
