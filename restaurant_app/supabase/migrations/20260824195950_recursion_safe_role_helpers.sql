-- ============================================================================
-- RECURSION-SAFE ROLE HELPERS
-- ----------------------------------------------------------------------------
-- WHY: public.profiles has RLS policies that call is_admin()/is_staff().
-- If those helpers read profiles under the caller's rights, Postgres raises
-- 42P17 (infinite recursion) because the SELECT re-triggers the same policies.
-- DESIGN: every helper below is SECURITY DEFINER (runs as table owner, which
-- RLS does not restrict) => the read terminates. Policies must ONLY ever call
-- these helpers and must NEVER subquery public.profiles directly.
-- PERF: bodies use scalar-subquery form "(SELECT auth.uid())" so Postgres
-- computes the value once per statement (InitPlan) instead of once per row.
-- HARDENING: SET search_path = '' forces fully-qualified references.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT p.role
  FROM public.profiles p
  WHERE p.id = (SELECT auth.uid())
  LIMIT 1;
$function$;

CREATE OR REPLACE FUNCTION public.is_staff()
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT public.get_my_role() IN ('waiter', 'kitchen', 'cashier', 'driver', 'manager', 'admin');
$function$;

CREATE OR REPLACE FUNCTION public.is_manager_or_admin()
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT public.get_my_role() IN ('manager', 'admin');
$function$;

CREATE OR REPLACE FUNCTION public.has_role(p_roles text[])
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT public.get_my_role() = ANY (p_roles);
$function$;

CREATE OR REPLACE FUNCTION public.is_admin_for_restaurant(target_restaurant_id uuid)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = ''
AS $function$
  -- FIX: previously referenced non-existent public.users table
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles pr
    WHERE pr.id = (SELECT auth.uid())
      AND pr.role = 'admin'
      AND pr.restaurant_id = target_restaurant_id
  );
$function$;

-- ============================================================================
-- EXECUTE PRIVILEGES
-- - Helpers used INSIDE RLS policy expressions must stay executable by
--   `authenticated`, otherwise every covered query fails with permission
--   denied when the policy expression is evaluated.
-- - Trigger-only functions are revoked from client roles entirely.
-- - Nothing is executable by `anon` / PUBLIC anymore (advisor lint 0028/0029).
-- ============================================================================

REVOKE EXECUTE ON FUNCTION public.get_my_role() FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.is_staff() FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.is_manager_or_admin() FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.has_role(text[]) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.is_admin_for_restaurant(uuid) FROM PUBLIC, anon;

-- NOTE (2026-09-04): trigger-only functions below are CREATED by migration
-- 20260904000000_account_linking_hardening. The guards use IF EXISTS checks
-- so a fresh `supabase db reset` never fails on ordering.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'handle_new_user') THEN
    REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM PUBLIC, anon, authenticated;
    GRANT EXECUTE ON FUNCTION public.handle_new_user() TO service_role;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'enforce_profile_insert_role') THEN
    REVOKE EXECUTE ON FUNCTION public.enforce_profile_insert_role() FROM PUBLIC, anon, authenticated;
    GRANT EXECUTE ON FUNCTION public.enforce_profile_insert_role() TO service_role;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'enforce_profile_update_role') THEN
    REVOKE EXECUTE ON FUNCTION public.enforce_profile_update_role() FROM PUBLIC, anon, authenticated;
    GRANT EXECUTE ON FUNCTION public.enforce_profile_update_role() TO service_role;
  END IF;
END $$;

GRANT EXECUTE ON FUNCTION public.get_my_role() TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.is_staff() TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.is_manager_or_admin() TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.has_role(text[]) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.is_admin_for_restaurant(uuid) TO authenticated, service_role;
-- (grants for handle_new_user/enforce_* live in 20260904000000, which creates them)
