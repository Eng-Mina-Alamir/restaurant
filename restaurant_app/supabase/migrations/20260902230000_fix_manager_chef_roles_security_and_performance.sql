-- ==============================================================================
-- 🚀 MIGRATION: Fix Manager Chef Roles, Security Hardening & Performance
-- ==============================================================================

-- 1. Update profiles_role_check constraint to support managerChef / manager_chef
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_role_check;
ALTER TABLE public.profiles ADD CONSTRAINT profiles_role_check 
  CHECK (role = ANY (ARRAY[
    'customer'::text, 
    'waiter'::text, 
    'kitchen'::text, 
    'manager'::text, 
    'driver'::text, 
    'cashier'::text, 
    'admin'::text,
    'managerChef'::text,
    'manager_chef'::text
  ]));

-- 2. Update role helper functions with search_path and managerChef support
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS text
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT p.role
  FROM public.profiles p
  WHERE p.id = (SELECT auth.uid())
  LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.is_staff()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.get_my_role() IN ('waiter', 'kitchen', 'cashier', 'driver', 'manager', 'admin', 'managerChef', 'manager_chef');
$$;

CREATE OR REPLACE FUNCTION public.is_manager_or_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.get_my_role() IN ('manager', 'admin', 'managerChef', 'manager_chef');
$$;

CREATE OR REPLACE FUNCTION public.has_role(p_roles text[])
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.get_my_role() = ANY (p_roles);
$$;

-- NOTE (2026-09-04): guarded with IF EXISTS — several of these functions only
-- exist on long-lived projects (or are created later by 20260904000000), so a
-- fresh `supabase db reset` must not fail here on ordering.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'set_order_number') THEN
    EXECUTE 'ALTER FUNCTION public.set_order_number() SET search_path = public';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'validate_order_status_transition') THEN
    EXECUTE 'ALTER FUNCTION public.validate_order_status_transition() SET search_path = public';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'log_order_status_change') THEN
    EXECUTE 'ALTER FUNCTION public.log_order_status_change() SET search_path = public';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'sync_delivery_to_order_status') THEN
    EXECUTE 'ALTER FUNCTION public.sync_delivery_to_order_status() SET search_path = public';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'sync_order_cancel_to_delivery') THEN
    EXECUTE 'ALTER FUNCTION public.sync_order_cancel_to_delivery() SET search_path = public';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'archive_old_orders') THEN
    REVOKE EXECUTE ON FUNCTION public.archive_old_orders() FROM public, anon, authenticated;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'log_order_status_change') THEN
    REVOKE EXECUTE ON FUNCTION public.log_order_status_change() FROM public, anon, authenticated;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'sync_delivery_to_order_status') THEN
    REVOKE EXECUTE ON FUNCTION public.sync_delivery_to_order_status() FROM public, anon, authenticated;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'sync_order_cancel_to_delivery') THEN
    REVOKE EXECUTE ON FUNCTION public.sync_order_cancel_to_delivery() FROM public, anon, authenticated;
  END IF;
END $$;

-- 4. Revoke public/anon/authenticated execution on internal triggers and batch functions
-- (covered by the guarded DO block above)
-- NOTE (2026-09-04): guarded with IF EXISTS — these functions are created by
-- migration 20260904000000_account_linking_hardening, so a fresh reset must
-- not fail here on ordering. (Grants for them live in that migration too.)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'handle_new_user') THEN
    REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM public, anon, authenticated;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'enforce_profile_insert_role') THEN
    REVOKE EXECUTE ON FUNCTION public.enforce_profile_insert_role() FROM public, anon, authenticated;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'enforce_profile_update_role') THEN
    REVOKE EXECUTE ON FUNCTION public.enforce_profile_update_role() FROM public, anon, authenticated;
  END IF;
END $$;

-- Revoke anon execution from RPC helpers.
-- NOTE (2026-09-04): earn_loyalty_points / redeem_loyalty_reward revokes live
-- in 20260904000000 alongside their CREATEs; is_admin() never existed.
REVOKE EXECUTE ON FUNCTION public.is_admin_for_restaurant(uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.is_manager_or_admin() FROM anon;
REVOKE EXECUTE ON FUNCTION public.is_staff() FROM anon;
REVOKE EXECUTE ON FUNCTION public.has_role(text[]) FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_my_role() FROM anon;

-- 5. Deduplicate permissive RLS policies
-- coupons
DROP POLICY IF EXISTS "coupons_select" ON public.coupons;
DROP POLICY IF EXISTS "coupons_all" ON public.coupons;

-- delivery_assignments
DROP POLICY IF EXISTS "delivery_assignments_insert" ON public.delivery_assignments;
DROP POLICY IF EXISTS "delivery_assignments_update_driver" ON public.delivery_assignments;

-- delivery_exceptions
DROP POLICY IF EXISTS "delivery_exceptions_all" ON public.delivery_exceptions;

-- inventory
DROP POLICY IF EXISTS "inventory_admin_delete" ON public.inventory;
DROP POLICY IF EXISTS "inventory_admin_insert" ON public.inventory;
DROP POLICY IF EXISTS "inventory_admin_update" ON public.inventory;
DROP POLICY IF EXISTS "inventory_all" ON public.inventory;
DROP POLICY IF EXISTS "inventory_select" ON public.inventory;
DROP POLICY IF EXISTS "inventory_select_policy" ON public.inventory;

CREATE POLICY "inventory_select_policy" ON public.inventory 
  FOR SELECT TO authenticated 
  USING ((SELECT is_staff()));

CREATE POLICY "inventory_insert_policy" ON public.inventory 
  FOR INSERT TO authenticated 
  WITH CHECK ((SELECT is_staff()));

CREATE POLICY "inventory_update_policy" ON public.inventory 
  FOR UPDATE TO authenticated 
  USING ((SELECT is_staff())) 
  WITH CHECK ((SELECT is_staff()));

CREATE POLICY "inventory_delete_policy" ON public.inventory 
  FOR DELETE TO authenticated 
  USING ((SELECT is_manager_or_admin()));

-- tables
DROP POLICY IF EXISTS "tables_all_staff" ON public.tables;
DROP POLICY IF EXISTS "tables_select" ON public.tables;

-- menu_items
DROP POLICY IF EXISTS "menu_items_all" ON public.menu_items;
DROP POLICY IF EXISTS "menu_items_select" ON public.menu_items;

-- 6. Add covering indexes for unindexed foreign keys
CREATE INDEX IF NOT EXISTS idx_cwt_wallet_id ON public.customer_wallet_transactions(wallet_id);
CREATE INDEX IF NOT EXISTS idx_discounts_restaurant_id ON public.discounts(restaurant_id);

-- 7. Enable Realtime on inventory and recipes
ALTER TABLE public.inventory REPLICA IDENTITY FULL;
ALTER TABLE public.recipes REPLICA IDENTITY FULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'inventory'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.inventory;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'recipes'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.recipes;
  END IF;
END $$;
