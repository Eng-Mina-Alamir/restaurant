-- ============================================================================
-- FIXUP: complete the EXECUTE lockdown missed in the first pass.
-- - public.is_admin() was left executable by anon/PUBLIC.
-- - earn_loyalty_points / redeem_loyalty_reward were never restricted;
--   the app only ever calls them as authenticated users (loyalty repository).
-- NOTE: remaining advisor WARNs about `authenticated` executing SECURITY
-- DEFINER helpers are INTENTIONAL: RLS policy expressions are evaluated under
-- the caller's role, so authenticated must retain EXECUTE or every covered
-- query fails with permission denied. See recursion_safe_role_helpers header.
-- ============================================================================

REVOKE EXECUTE ON FUNCTION public.is_admin() FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.earn_loyalty_points(text) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.redeem_loyalty_reward(text) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.earn_loyalty_points(text) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.redeem_loyalty_reward(text) TO authenticated, service_role;
