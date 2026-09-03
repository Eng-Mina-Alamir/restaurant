-- ==============================================================================
-- ACCOUNT LINKING HARDENING (2026-09-04)
-- ------------------------------------------------------------------------------
-- Closes the gaps found in the auth <-> profiles <-> domain linking audit:
--
--  1. `handle_new_user()` + `on_auth_user_created` trigger NEVER EXISTED.
--     Old migrations only REVOKE/GRANT on it, and the Flutter client assumes
--     "profile is auto-created". A fresh `supabase db reset` therefore leaves
--     every signUp without a `profiles` row. This migration creates the
--     function and trigger for real.
--  2. `enforce_profile_insert_role()` / `enforce_profile_update_role()` are
--     referenced by old REVOKEs but were never created either, so a client
--     could self-insert `profiles(id, role='admin')` (RLS only checks
--     `id = auth.uid()`). Created here + enforced via BEFORE triggers.
--  3. `loyalty_accounts` had no bootstrap: every new user read 0 points and
--     the client invented a fake "150 silver" fallback. An AFTER INSERT
--     trigger now creates the row server-side.
--  4. `profiles.restaurant_id NOT NULL` with no DEFAULT turns any bad
--     `restaurant_id` metadata into an orphaned auth user. The function
--     validates the UUID against `restaurants(id)` and falls back to the
--     default/single-tenant restaurant, then to any existing restaurant.
--  5. FK `ON DELETE` gaps: `cart_items.user_id` (no action -> orphaned cart
--     blocks profile delete) becomes CASCADE; `order_status_log.changed_by`
--     becomes SET NULL so audit history survives staff deletion.
--     (`delivery_assignments.driver_id` / `chat_messages.sender_id` keep
--     blocking deletes on purpose: dispatch + conversation integrity.)
--  6. RLS gaps:
--     a. `driver_locations`: customers could never track their own driver
--        (staff-only). Adds a customer-own-orders read policy.
--     b. `coupons` SELECT was `TO anon, authenticated USING (true)` ->
--        anonymous code harvesting incl. inactive/expired. Restricted to
--        authenticated + active + unexpired.
--     c. `reservations` INSERT allowed ANY authenticated user to create
--        orphan (`user_id IS NULL`) bookings owned by nobody. Orphans now
--        require staff (walk-in/phone bookings); customers must own theirs.
--  7. `get_my_order_driver(BIGINT)` mismatches `orders.id TEXT`, so the
--     customer driver card always came back empty. Adds a TEXT overload.
--
-- Every statement is idempotent (IF NOT EXISTS / DROP IF EXISTS / CREATE OR
-- REPLACE) and uses InitPlan-safe `(SELECT auth.uid())` + recursion-safe
-- helpers only.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 0. profiles.restaurant_id: allow NULL so a missing/invalid restaurant can
--    never orphan an auth user. The trigger below still resolves the best
--    known restaurant whenever one exists.
-- ------------------------------------------------------------------------------
ALTER TABLE public.profiles ALTER COLUMN restaurant_id DROP NOT NULL;

-- ------------------------------------------------------------------------------
-- 1. handle_new_user(): auth.users -> profiles (+ validated restaurant).
--    SECURITY: role is ALWAYS 'customer' here. Staff roles are provisioned
--    later by managers/admins through the enforced update path.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  v_name TEXT;
  v_phone TEXT;
  v_email TEXT;
  v_restaurant_id UUID;
  v_meta_restaurant TEXT;
BEGIN
  v_meta_restaurant := NULLIF(TRIM(NEW.raw_user_meta_data ->> 'restaurant_id'), '');
  v_restaurant_id := NULL;

  -- Accept the client-supplied restaurant ONLY when it is a well-formed UUID
  -- that actually exists (prevents cross-tenant self-assignment).
  IF v_meta_restaurant IS NOT NULL THEN
    BEGIN
      IF EXISTS (SELECT 1 FROM public.restaurants r WHERE r.id = v_meta_restaurant::uuid) THEN
        v_restaurant_id := v_meta_restaurant::uuid;
      END IF;
    EXCEPTION WHEN invalid_text_representation THEN
      v_restaurant_id := NULL;
    END;
  END IF;

  -- Single-tenant default, then any restaurant, then NULL (column nullable).
  IF v_restaurant_id IS NULL THEN
    SELECT r.id INTO v_restaurant_id
    FROM public.restaurants r
    WHERE r.id = '1e08b47c-15be-4604-a913-431af7fbd54f'::uuid
    LIMIT 1;
  END IF;
  IF v_restaurant_id IS NULL THEN
    SELECT r.id INTO v_restaurant_id FROM public.restaurants r LIMIT 1;
  END IF;

  v_name := NULLIF(TRIM(COALESCE(NEW.raw_user_meta_data ->> 'name', '')), '');
  v_phone := NULLIF(TRIM(COALESCE(
    NEW.raw_user_meta_data ->> 'phone',
    NEW.phone,
    ''
  )), '');
  v_email := NULLIF(NEW.email, '');

  INSERT INTO public.profiles (id, restaurant_id, name, email, phone, role)
  VALUES (
    NEW.id,
    v_restaurant_id,
    COALESCE(v_name, 'مستخدم جديد'),
    v_email,
    v_phone,
    'customer'
  )
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
END;
$function$;

-- Trigger on auth.users (the one the client always assumed existed).
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ------------------------------------------------------------------------------
-- 2. Privilege-escalation guards on profiles (the functions old migrations
--    REVOKE without ever creating).
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.enforce_profile_insert_role()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
BEGIN
  -- Self-provisioning can only ever mint 'customer', regardless of RLS.
  IF NOT public.is_manager_or_admin() THEN
    NEW.role := 'customer';
  END IF;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.enforce_profile_update_role()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
BEGIN
  IF NEW.role IS DISTINCT FROM OLD.role
     AND NOT public.is_manager_or_admin() THEN
    RAISE EXCEPTION 'Changing role requires manager or admin privileges';
  END IF;
  IF NEW.restaurant_id IS DISTINCT FROM OLD.restaurant_id
     AND NOT public.is_manager_or_admin() THEN
    RAISE EXCEPTION 'Changing restaurant_id requires manager or admin privileges';
  END IF;
  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_enforce_profile_insert_role ON public.profiles;
CREATE TRIGGER trg_enforce_profile_insert_role
  BEFORE INSERT ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.enforce_profile_insert_role();

DROP TRIGGER IF EXISTS trg_enforce_profile_update_role ON public.profiles;
CREATE TRIGGER trg_enforce_profile_update_role
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.enforce_profile_update_role();

-- Trigger-only functions must never be callable by client roles.
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.enforce_profile_insert_role() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.enforce_profile_update_role() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO service_role;
GRANT EXECUTE ON FUNCTION public.enforce_profile_insert_role() TO service_role;
GRANT EXECUTE ON FUNCTION public.enforce_profile_update_role() TO service_role;

-- ------------------------------------------------------------------------------
-- 3. Loyalty bootstrap: every profile gets its ledger row server-side.
--    (Removes the need for the client's fake "150 points" fallback.)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_profile_loyalty_bootstrap()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
BEGIN
  INSERT INTO public.loyalty_accounts (user_id, current_points, lifetime_points)
  VALUES (NEW.id, 0, 0)
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_profile_loyalty_bootstrap ON public.profiles;
CREATE TRIGGER trg_profile_loyalty_bootstrap
  AFTER INSERT ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_profile_loyalty_bootstrap();

REVOKE EXECUTE ON FUNCTION public.handle_profile_loyalty_bootstrap() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.handle_profile_loyalty_bootstrap() TO service_role;

-- Backfill loyalty rows for pre-existing profiles that never got one.
INSERT INTO public.loyalty_accounts (user_id, current_points, lifetime_points)
SELECT p.id, 0, 0 FROM public.profiles p
LEFT JOIN public.loyalty_accounts la ON la.user_id = p.id
WHERE la.user_id IS NULL
ON CONFLICT (user_id) DO NOTHING;

-- ------------------------------------------------------------------------------
-- 4. FK ON DELETE hardening (safe subset).
-- ------------------------------------------------------------------------------

-- cart_items.user_id: drop orphaned carts with the profile instead of
-- blocking the delete / stranding rows.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'cart_items_user_id_fkey'
      AND conrelid = 'public.cart_items'::regclass
  ) THEN
    ALTER TABLE public.cart_items DROP CONSTRAINT cart_items_user_id_fkey;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'cart_items_user_id_fkey'
      AND conrelid = 'public.cart_items'::regclass
  ) THEN
    ALTER TABLE public.cart_items
      ADD CONSTRAINT cart_items_user_id_fkey
      FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
  END IF;
END $$;

-- order_status_log.changed_by: keep the audit row, null the departed author.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'order_status_log_changed_by_fkey'
      AND conrelid = 'public.order_status_log'::regclass
  ) THEN
    ALTER TABLE public.order_status_log DROP CONSTRAINT order_status_log_changed_by_fkey;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'order_status_log_changed_by_fkey'
      AND conrelid = 'public.order_status_log'::regclass
  ) THEN
    ALTER TABLE public.order_status_log
      ADD CONSTRAINT order_status_log_changed_by_fkey
      FOREIGN KEY (changed_by) REFERENCES public.profiles(id) ON DELETE SET NULL;
  END IF;
END $$;

-- NOTE (deliberate no-change): delivery_assignments.driver_id and
-- chat_messages.sender_id keep blocking deletes (NO ACTION). Reassign the
-- driver / preserve the conversation before deleting a profile.

-- ------------------------------------------------------------------------------
-- 5a. RLS: customers can read the live location of THEIR order's driver.
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS driver_locations_select_own_order ON public.driver_locations;
CREATE POLICY driver_locations_select_own_order ON public.driver_locations
  FOR SELECT TO authenticated
  USING (
    driver_id = (SELECT auth.uid())
    OR (SELECT public.is_staff())
    OR EXISTS (
      SELECT 1
      FROM public.delivery_assignments da
      JOIN public.orders o ON o.id::text = da.order_id::text
      WHERE da.driver_id = driver_locations.driver_id
        AND o.customer_id = (SELECT auth.uid())
    )
  );

-- ------------------------------------------------------------------------------
-- 5b. RLS: coupons are redeemable catalog data, not an anonymous dump.
--     Anonymous harvesting (incl. inactive/expired codes) is denied; signed-in
--     users see only live codes. Managers keep full CRUD via existing policies.
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS coupons_select_policy ON public.coupons;
CREATE POLICY coupons_select_policy ON public.coupons
  FOR SELECT TO authenticated
  USING (is_active = true AND (expires_at IS NULL OR expires_at > NOW()));

-- ------------------------------------------------------------------------------
-- 5c. RLS: reservations must be owned. Only staff may file orphan (walk-in /
--     phone) bookings; customers always stamp their own user_id.
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS reservations_insert_policy ON public.reservations;
CREATE POLICY reservations_insert_policy ON public.reservations
  FOR INSERT TO authenticated
  WITH CHECK (
    user_id = (SELECT auth.uid())
    OR (SELECT public.is_staff())
  );

-- ------------------------------------------------------------------------------
-- 6. get_my_order_driver TEXT overload (orders.id is TEXT; the BIGINT-only
--    version could never match and the tracking card stayed empty).
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_my_order_driver(p_order_id TEXT)
RETURNS TABLE (
  driver_id UUID,
  name TEXT,
  phone TEXT,
  rating NUMERIC,
  vehicle_info TEXT
)
SECURITY DEFINER
SET search_path = public
LANGUAGE sql
STABLE
AS $$
  SELECT p.id, p.name, p.phone, p.rating, p.vehicle_info
  FROM public.delivery_assignments da
  JOIN public.orders o ON o.id::text = da.order_id::text
  JOIN public.profiles p ON p.id = da.driver_id
  WHERE da.order_id::text = p_order_id::text
    AND o.customer_id = (SELECT auth.uid())
  LIMIT 1;
$$;

REVOKE ALL ON FUNCTION public.get_my_order_driver(TEXT) FROM anon;
GRANT EXECUTE ON FUNCTION public.get_my_order_driver(TEXT) TO authenticated;

-- ------------------------------------------------------------------------------
-- 7. Loyalty RPCs the client already calls (earn_loyalty_points /
--    redeem_loyalty_reward) but which were NEVER created server-side — every
--    call failed and was swallowed as a warning, so points never accrued.
--    Both derive the user from auth.uid() (never from a client argument).
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.earn_loyalty_points(p_order_id TEXT)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  v_uid UUID;
  v_total NUMERIC;
  v_earned INT;
BEGIN
  v_uid := (SELECT auth.uid());
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT o.total_amount INTO v_total
  FROM public.orders o
  WHERE o.id::text = p_order_id::text
    AND o.customer_id = v_uid
  LIMIT 1;

  IF v_total IS NULL THEN
    RAISE EXCEPTION 'Order not found or not owned by caller';
  END IF;

  -- Idempotency: one earn per order.
  IF EXISTS (
    SELECT 1 FROM public.loyalty_transactions t
    WHERE t.order_id::text = p_order_id::text AND t.type = 'earn'
  ) THEN
    RETURN;
  END IF;

  v_earned := GREATEST(FLOOR(v_total / 10), 0)::INT;

  INSERT INTO public.loyalty_accounts (user_id, current_points, lifetime_points)
  VALUES (v_uid, v_earned, v_earned)
  ON CONFLICT (user_id) DO UPDATE SET
    current_points = public.loyalty_accounts.current_points + EXCLUDED.current_points,
    lifetime_points = public.loyalty_accounts.lifetime_points + EXCLUDED.lifetime_points,
    updated_at = NOW();

  INSERT INTO public.loyalty_transactions (user_id, points, type, description, order_id)
  VALUES (v_uid, v_earned, 'earn', 'نقاط طلب ' || p_order_id, p_order_id);
END;
$function$;

CREATE OR REPLACE FUNCTION public.redeem_loyalty_reward(p_reward_id TEXT)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  v_uid UUID;
  v_cost INT;
  v_balance INT;
BEGIN
  v_uid := (SELECT auth.uid());
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT r.points_cost INTO v_cost
  FROM public.loyalty_rewards r
  WHERE r.id::text = p_reward_id::text AND r.is_active = true
  LIMIT 1;

  IF v_cost IS NULL THEN
    RAISE EXCEPTION 'Reward not found or inactive';
  END IF;

  SELECT la.current_points INTO v_balance
  FROM public.loyalty_accounts la
  WHERE la.user_id = v_uid
  LIMIT 1;

  IF v_balance IS NULL OR v_balance < v_cost THEN
    RAISE EXCEPTION 'Insufficient loyalty points';
  END IF;

  UPDATE public.loyalty_accounts
  SET current_points = current_points - v_cost,
      updated_at = NOW()
  WHERE user_id = v_uid;

  INSERT INTO public.loyalty_transactions (user_id, points, type, description)
  VALUES (v_uid, -v_cost, 'redeem', 'استبدال مكافأة ' || p_reward_id);
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.earn_loyalty_points(TEXT) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.redeem_loyalty_reward(TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.earn_loyalty_points(TEXT) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.redeem_loyalty_reward(TEXT) TO authenticated, service_role;
