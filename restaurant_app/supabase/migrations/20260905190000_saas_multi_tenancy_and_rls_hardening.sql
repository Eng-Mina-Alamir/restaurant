-- 1. SaaS Columns on restaurants table
ALTER TABLE public.restaurants ADD COLUMN IF NOT EXISTS currency VARCHAR(10) NOT NULL DEFAULT 'ج.م';
ALTER TABLE public.restaurants ADD COLUMN IF NOT EXISTS vat_number VARCHAR(50) DEFAULT '300123456700003';
ALTER TABLE public.restaurants ADD COLUMN IF NOT EXISTS subscription_tier VARCHAR(20) NOT NULL DEFAULT 'pro';
ALTER TABLE public.restaurants ADD COLUMN IF NOT EXISTS subscription_status VARCHAR(20) NOT NULL DEFAULT 'active';
ALTER TABLE public.restaurants ADD COLUMN IF NOT EXISTS trial_ends_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '14 days');
ALTER TABLE public.restaurants ADD COLUMN IF NOT EXISTS max_tables INT NOT NULL DEFAULT 50;
ALTER TABLE public.restaurants ADD COLUMN IF NOT EXISTS max_staff INT NOT NULL DEFAULT 20;

-- 2. Add restaurant_id to tables that were missing it
ALTER TABLE public.tables ADD COLUMN IF NOT EXISTS restaurant_id UUID REFERENCES public.restaurants(id) ON DELETE CASCADE DEFAULT '1e08b47c-15be-4604-a913-431af7fbd54f';
UPDATE public.tables SET restaurant_id = '1e08b47c-15be-4604-a913-431af7fbd54f' WHERE restaurant_id IS NULL;
CREATE INDEX IF NOT EXISTS idx_tables_restaurant_id ON public.tables(restaurant_id);

ALTER TABLE public.categories ADD COLUMN IF NOT EXISTS restaurant_id UUID REFERENCES public.restaurants(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_categories_restaurant_id ON public.categories(restaurant_id);

ALTER TABLE public.coupons ADD COLUMN IF NOT EXISTS restaurant_id UUID REFERENCES public.restaurants(id) ON DELETE CASCADE DEFAULT '1e08b47c-15be-4604-a913-431af7fbd54f';
UPDATE public.coupons SET restaurant_id = '1e08b47c-15be-4604-a913-431af7fbd54f' WHERE restaurant_id IS NULL;
CREATE INDEX IF NOT EXISTS idx_coupons_restaurant_id ON public.coupons(restaurant_id);

ALTER TABLE public.loyalty_rewards ADD COLUMN IF NOT EXISTS restaurant_id UUID REFERENCES public.restaurants(id) ON DELETE CASCADE DEFAULT '1e08b47c-15be-4604-a913-431af7fbd54f';
UPDATE public.loyalty_rewards SET restaurant_id = '1e08b47c-15be-4604-a913-431af7fbd54f' WHERE restaurant_id IS NULL;
CREATE INDEX IF NOT EXISTS idx_loyalty_rewards_restaurant_id ON public.loyalty_rewards(restaurant_id);

ALTER TABLE public.table_service_requests ADD COLUMN IF NOT EXISTS restaurant_id UUID REFERENCES public.restaurants(id) ON DELETE CASCADE DEFAULT '1e08b47c-15be-4604-a913-431af7fbd54f';
UPDATE public.table_service_requests SET restaurant_id = '1e08b47c-15be-4604-a913-431af7fbd54f' WHERE restaurant_id IS NULL;
CREATE INDEX IF NOT EXISTS idx_table_service_requests_restaurant_id ON public.table_service_requests(restaurant_id);

-- 3. Tenant helper functions
CREATE OR REPLACE FUNCTION public.get_my_restaurant_id()
RETURNS uuid
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT p.restaurant_id
  FROM public.profiles p
  WHERE p.id = (SELECT auth.uid())
  LIMIT 1;
$function$;

REVOKE EXECUTE ON FUNCTION public.get_my_restaurant_id() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_my_restaurant_id() TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.is_staff_for_restaurant(target_restaurant_id uuid)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles pr
    WHERE pr.id = (SELECT auth.uid())
      AND pr.restaurant_id = target_restaurant_id
      AND pr.role IN ('waiter', 'kitchen', 'cashier', 'driver', 'manager', 'admin', 'manager_chef')
  );
$function$;

REVOKE EXECUTE ON FUNCTION public.is_staff_for_restaurant(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_staff_for_restaurant(uuid) TO authenticated, service_role;

-- 4. Self-service restaurant tenant onboarding RPC
CREATE OR REPLACE FUNCTION public.register_new_tenant(
  p_name text,
  p_address text DEFAULT 'الفرع الرئيسي',
  p_phone text DEFAULT '0000000000',
  p_currency text DEFAULT 'ج.م',
  p_vat_number text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_user_id uuid;
  v_restaurant_id uuid;
  v_res jsonb;
BEGIN
  v_user_id := (SELECT auth.uid());
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required to register a restaurant';
  END IF;

  -- 1. Create the restaurant
  INSERT INTO public.restaurants (
    name,
    address,
    phone,
    currency,
    vat_number,
    admin_id,
    subscription_tier,
    subscription_status,
    trial_ends_at
  )
  VALUES (
    p_name,
    COALESCE(p_address, 'الفرع الرئيسي'),
    COALESCE(p_phone, '0000000000'),
    COALESCE(p_currency, 'ج.م'),
    p_vat_number,
    v_user_id,
    'pro',
    'trialing',
    NOW() + INTERVAL '14 days'
  )
  RETURNING id INTO v_restaurant_id;

  -- 2. Update or insert the user profile
  UPDATE public.profiles
  SET
    restaurant_id = v_restaurant_id,
    role = 'admin',
    updated_at = NOW()
  WHERE id = v_user_id;

  IF NOT FOUND THEN
    INSERT INTO public.profiles (id, restaurant_id, name, role)
    VALUES (v_user_id, v_restaurant_id, 'مدير المطعم', 'admin');
  END IF;

  -- 3. Seed starter tables
  INSERT INTO public.tables (restaurant_id, table_number, capacity, location, status)
  VALUES
    (v_restaurant_id, 1, 4, 'الصالة الداخلية', 'available'),
    (v_restaurant_id, 2, 4, 'الصالة الداخلية', 'available'),
    (v_restaurant_id, 3, 6, 'العائلات', 'available'),
    (v_restaurant_id, 4, 2, 'الخارجي / تراس', 'available');

  -- 4. Seed starter categories
  INSERT INTO public.categories (restaurant_id, name, name_ar, icon, sort_order)
  VALUES
    (v_restaurant_id, 'وجبات رئيسية', 'وجبات رئيسية', 'flame', 1),
    (v_restaurant_id, 'مقبلات وسلطات', 'مقبلات وسلطات', 'salad', 2),
    (v_restaurant_id, 'مشروبات', 'مشروبات', 'glass', 3),
    (v_restaurant_id, 'حلويات', 'حلويات', 'cake', 4);

  SELECT jsonb_build_object(
    'id', v_restaurant_id,
    'name', p_name,
    'currency', p_currency,
    'subscription_tier', 'pro',
    'subscription_status', 'trialing'
  ) INTO v_res;

  RETURN v_res;
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.register_new_tenant(text, text, text, text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.register_new_tenant(text, text, text, text, text) TO authenticated, service_role;

-- 5. Tighten RLS policies for tenant isolation
DROP POLICY IF EXISTS orders_select_policy ON public.orders;
CREATE POLICY orders_select_policy ON public.orders FOR SELECT TO authenticated
  USING (
    customer_id = (SELECT auth.uid())
    OR (restaurant_id = (SELECT public.get_my_restaurant_id()) AND (SELECT public.is_staff()))
  );

DROP POLICY IF EXISTS orders_update_policy ON public.orders;
CREATE POLICY orders_update_policy ON public.orders FOR UPDATE TO authenticated
  USING (
    restaurant_id = (SELECT public.get_my_restaurant_id()) AND (SELECT public.is_staff())
  )
  WITH CHECK (
    restaurant_id = (SELECT public.get_my_restaurant_id()) AND (SELECT public.is_staff())
  );

DROP POLICY IF EXISTS tables_select_policy ON public.tables;
CREATE POLICY tables_select_policy ON public.tables FOR SELECT TO anon, authenticated
  USING (
    restaurant_id = (SELECT public.get_my_restaurant_id())
    OR (SELECT auth.uid()) IS NULL
    OR restaurant_id IS NULL
  );

DROP POLICY IF EXISTS inventory_select_policy ON public.inventory;
CREATE POLICY inventory_select_policy ON public.inventory FOR SELECT TO authenticated
  USING (
    restaurant_id = (SELECT public.get_my_restaurant_id()) AND (SELECT public.is_staff())
  );

DROP POLICY IF EXISTS inventory_admin_insert ON public.inventory;
CREATE POLICY inventory_admin_insert ON public.inventory FOR INSERT TO authenticated
  WITH CHECK (
    restaurant_id = (SELECT public.get_my_restaurant_id()) AND (SELECT public.is_manager_or_admin())
  );

DROP POLICY IF EXISTS inventory_admin_update ON public.inventory;
CREATE POLICY inventory_admin_update ON public.inventory FOR UPDATE TO authenticated
  USING (
    restaurant_id = (SELECT public.get_my_restaurant_id()) AND (SELECT public.is_manager_or_admin())
  )
  WITH CHECK (
    restaurant_id = (SELECT public.get_my_restaurant_id()) AND (SELECT public.is_manager_or_admin())
  );

DROP POLICY IF EXISTS inventory_admin_delete ON public.inventory;
CREATE POLICY inventory_admin_delete ON public.inventory FOR DELETE TO authenticated
  USING (
    restaurant_id = (SELECT public.get_my_restaurant_id()) AND (SELECT public.is_manager_or_admin())
  );
