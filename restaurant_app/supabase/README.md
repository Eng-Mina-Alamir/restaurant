# Supabase Local Project Structure

This directory is the **single source of truth** for the database schema.

## Layout

```
supabase/
├── config.toml      # local CLI project config (placeholder project_id)
└── migrations/      # timestamped migration history — mirrors the REMOTE history
```

## Reconciliation status (2026-08-24)

The remote project's `supabase_migration_list` contains **15 migrations**:

| Version | Name | Mirrored locally? |
|---------|------|-------------------|
| 20260821100352 | create_profile_on_signup_trigger | ❌ dashboard-era (pre-CLI) |
| 20260821110748 | enforce_restaurant_id_on_profiles | ❌ dashboard-era |
| 20260821123030 | add_comprehensive_relations_and_fix_datatypes | ❌ dashboard-era |
| 20260821123129 | optimize_indexes_and_clean_policies | ❌ dashboard-era |
| 20260821123138 | drop_duplicate_indexes_and_clean_inventory_policy | ❌ dashboard-era |
| 20260824195950 → 20260824212010 | hardening pass + E2E fixes (10 files) | ✅ exact mirror |

The five 2026-08-21 migrations were applied through the Dashboard SQL Editor
before this directory existed and their SQL bodies are not recoverable from the
migration table. To backfill them locally run:

```bash
supabase db pull pre_cli_baseline   # diffs remote -> local as one squash file
```

## Rules (see DEPLOYMENT.md §3b)

1. **Never** apply schema changes via Dashboard SQL Editor.
2. New change → `supabase migration new <name>` → edit file → `supabase db push`.
3. File names MUST match `<version>_<name>.sql` exactly as recorded remotely,
   otherwise `supabase migration list` reports drift.
