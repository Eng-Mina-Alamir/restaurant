import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static security guard: fails the suite if any table in `supabase_schema.sql`
/// is created without a matching `ENABLE ROW LEVEL SECURITY` statement, or if
/// the server-side privilege-escalation guards go missing.
///
/// This keeps the deny-by-default guarantee enforced by CI instead of trust.
void main() {
  final schema = _loadSchema();

  group('Supabase schema RLS hardening guard', () {
    final createdTables = RegExp(
      r'CREATE TABLE IF NOT EXISTS public\.([a-z_]+)',
      caseSensitive: false,
    )
        .allMatches(schema)
        .map((m) => m.group(1)!)
        .toSet();

    final rlsEnabledTables = RegExp(
      r'ALTER TABLE\s+(?:ONLY\s+)?public\.([a-z_]+)\s+ENABLE ROW LEVEL SECURITY',
      caseSensitive: false,
    )
        .allMatches(schema)
        .map((m) => m.group(1)!)
        .toSet();

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
        reason: 'Tables without RLS are publicly readable/writable via the '
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
}

String _loadSchema() {
  const candidates = ['supabase_schema.sql', '../supabase_schema.sql'];
  for (final path in candidates) {
    final file = File(path);
    if (file.existsSync()) return file.readAsStringSync();
  }
  fail('supabase_schema.sql not found relative to test working directory');
}
