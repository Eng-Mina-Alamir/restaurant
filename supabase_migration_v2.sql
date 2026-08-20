-- ==============================================================================
-- 🍽️ RESTAURANT MANAGEMENT SYSTEM - PRODUCTION SUPABASE SCHEMA
-- مطعم ليالي المحروسة - مخطط قاعدة البيانات الإنتاجية الشامل والمؤمن بالكامل
-- ==============================================================================

-- 1. Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==============================================================================
-- 🛠️ PRE-MIGRATION LEGACY COMPATIBILITY & CLEANUP
-- ==============================================================================
DO $$
DECLARE
  pol RECORD;
  r RECORD;
BEGIN
  -- 1. Drop ALL legacy policies across all public tables so columns can be modified safely
  FOR pol IN (
    SELECT policyname, tablename 
    FROM pg_policies 
    WHERE schemaname = 'public'
  ) LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', pol.policyname, pol.tablename);
  END LOOP;

  -- 2. Drop ALL legacy foreign keys across all public tables so tables can be restructured cleanly
  FOR r IN (
    SELECT tc.table_name, tc.constraint_name
    FROM information_schema.table_constraints tc
    WHERE tc.constraint_type = 'FOREIGN KEY'
      AND tc.table_schema = 'public'
  ) LOOP
    EXECUTE 'ALTER TABLE public.' || quote_ident(r.table_name) || ' DROP CONSTRAINT IF EXISTS ' || quote_ident(r.constraint_name) || ' CASCADE;';
  END LOOP;

  -- 3. Universal restaurant_id sanitization: convert to TEXT, drop NOT NULL, set default across ANY existing table
  FOR r IN (
    SELECT table_name 
    FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND column_name = 'restaurant_id'
  ) LOOP
    EXECUTE 'ALTER TABLE public.' || quote_ident(r.table_name) || ' ALTER COLUMN restaurant_id DROP NOT NULL;';
    EXECUTE 'ALTER TABLE public.' || quote_ident(r.table_name) || ' ALTER COLUMN restaurant_id TYPE TEXT USING restaurant_id::text;';
    EXECUTE 'ALTER TABLE public.' || quote_ident(r.table_name) || ' ALTER COLUMN restaurant_id SET DEFAULT ''restaurant-1'';';
    EXECUTE 'UPDATE public.' || quote_ident(r.table_name) || ' SET restaurant_id = ''restaurant-1'' WHERE restaurant_id IS NULL;';
  END LOOP;

  -- 4. Convert category_id to TEXT if present on menu_items
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'menu_items' AND column_name = 'category_id') THEN
    ALTER TABLE public.menu_items ALTER COLUMN category_id TYPE TEXT USING category_id::text;
  END IF;
END $$;

-- ==============================================================================
-- 👤 PROFILES TABLE (Linked with Supabase Auth)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL DEFAULT 'مستخدم جديد',
    email TEXT,
    phone TEXT,
    role TEXT NOT NULL DEFAULT 'customer' CHECK (role IN ('customer', 'waiter', 'kitchen', 'manager', 'driver', 'cashier', 'admin')),
    avatar_url TEXT,
    restaurant_id TEXT DEFAULT 'restaurant-1',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 📋 CATEGORIES TABLE
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.categories (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    name_ar TEXT,
    icon TEXT,
    sort_order INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 🥘 MENU ITEMS TABLE
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.menu_items (
    id TEXT PRIMARY KEY,
    restaurant_id TEXT NOT NULL DEFAULT 'restaurant-1',
    category_id TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    image_url TEXT,
    is_available BOOLEAN NOT NULL DEFAULT TRUE,
    is_vegetarian BOOLEAN NOT NULL DEFAULT FALSE,
    is_spicy BOOLEAN NOT NULL DEFAULT FALSE,
    preparation_time NUMERIC(5, 2) DEFAULT 15,
    rating NUMERIC(3, 2) DEFAULT 5.0,
    order_count INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS restaurant_id TEXT DEFAULT 'restaurant-1';
ALTER TABLE public.menu_items ALTER COLUMN restaurant_id SET DEFAULT 'restaurant-1';
UPDATE public.menu_items SET restaurant_id = 'restaurant-1' WHERE restaurant_id IS NULL;

-- ==============================================================================
-- 🍟 MENU MODIFIER GROUPS & OPTIONS
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.menu_modifier_groups (
    id TEXT PRIMARY KEY,
    menu_item_id TEXT REFERENCES public.menu_items(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    is_required BOOLEAN DEFAULT FALSE,
    max_selection INT DEFAULT 1
);

CREATE TABLE IF NOT EXISTS public.menu_modifier_options (
    id TEXT PRIMARY KEY,
    modifier_group_id TEXT REFERENCES public.menu_modifier_groups(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    extra_price NUMERIC(10, 2) DEFAULT 0.00,
    is_available BOOLEAN DEFAULT TRUE
);

-- ==============================================================================
-- 🪑 RESTAURANT TABLES
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.tables (
    id TEXT PRIMARY KEY,
    table_number INT NOT NULL UNIQUE,
    capacity INT NOT NULL DEFAULT 4,
    location TEXT NOT NULL DEFAULT 'صالة',
    status TEXT NOT NULL DEFAULT 'available' CHECK (status IN ('available', 'occupied', 'reserved', 'needsCleaning')),
    current_order_id TEXT,
    assigned_waiter_id TEXT,
    last_updated TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 🧾 ORDERS TABLE
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.orders (
    id TEXT PRIMARY KEY,
    restaurant_id TEXT NOT NULL DEFAULT 'restaurant-1',
    customer_id TEXT,
    table_id TEXT,
    waiter_id TEXT,
    order_type TEXT NOT NULL DEFAULT 'dineIn' CHECK (order_type IN ('dineIn', 'takeaway', 'delivery')),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'preparing', 'ready', 'served', 'completed', 'cancelled', 'delivering', 'delivered', 'rejected')),
    subtotal NUMERIC(10, 2) DEFAULT 0.00,
    tax_amount NUMERIC(10, 2) DEFAULT 0.00,
    discount_amount NUMERIC(10, 2) DEFAULT 0.00,
    total_amount NUMERIC(10, 2) DEFAULT 0.00,
    payment_method TEXT,
    delivery_address TEXT,
    delivery_notes TEXT,
    estimated_minutes INT DEFAULT 20,
    items_json JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

-- ==============================================================================
-- 📦 ORDER ITEMS TABLE (Detailed Line Items)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.order_items (
    id BIGSERIAL PRIMARY KEY,
    order_id TEXT REFERENCES public.orders(id) ON DELETE CASCADE,
    menu_item_id TEXT,
    item_name TEXT NOT NULL,
    price NUMERIC(10, 2) NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    total_price NUMERIC(10, 2) NOT NULL,
    special_notes TEXT,
    modifiers_json JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 📍 DRIVER LOCATIONS (Realtime GPS Tracking)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.driver_locations (
    id BIGSERIAL PRIMARY KEY,
    driver_id TEXT NOT NULL,
    order_id TEXT,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 📅 RESERVATIONS TABLE
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.reservations (
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    customer_name TEXT NOT NULL,
    phone TEXT NOT NULL,
    party_size INT NOT NULL DEFAULT 2,
    reservation_time TIMESTAMPTZ NOT NULL,
    table_id TEXT,
    table_number INT,
    status TEXT DEFAULT 'confirmed' CHECK (status IN ('pending', 'confirmed', 'seated', 'cancelled', 'completed')),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.reservations ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.reservations ADD COLUMN IF NOT EXISTS customer_name TEXT;
ALTER TABLE public.reservations ADD COLUMN IF NOT EXISTS phone TEXT;
ALTER TABLE public.reservations ADD COLUMN IF NOT EXISTS party_size INT DEFAULT 2;
ALTER TABLE public.reservations ADD COLUMN IF NOT EXISTS reservation_time TIMESTAMPTZ;
ALTER TABLE public.reservations ADD COLUMN IF NOT EXISTS table_id TEXT;
ALTER TABLE public.reservations ADD COLUMN IF NOT EXISTS table_number INT;
ALTER TABLE public.reservations ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'confirmed';
ALTER TABLE public.reservations ADD COLUMN IF NOT EXISTS notes TEXT;
ALTER TABLE public.reservations ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();

-- ==============================================================================
-- 🏷️ COUPONS TABLE
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.coupons (
    id TEXT PRIMARY KEY,
    code TEXT NOT NULL UNIQUE,
    title TEXT,
    discount_type TEXT DEFAULT 'percentage' CHECK (discount_type IN ('percentage', 'fixed')),
    discount_value NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    discount_percent NUMERIC(5, 2) DEFAULT 0.00,
    min_order_amount NUMERIC(10, 2) DEFAULT 0.00,
    max_discount NUMERIC(10, 2),
    usage_limit INT,
    usage_count INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    expires_at TIMESTAMPTZ
);

ALTER TABLE public.coupons ADD COLUMN IF NOT EXISTS code TEXT;
ALTER TABLE public.coupons ADD COLUMN IF NOT EXISTS title TEXT;
ALTER TABLE public.coupons ADD COLUMN IF NOT EXISTS discount_type TEXT DEFAULT 'percentage';
ALTER TABLE public.coupons ADD COLUMN IF NOT EXISTS discount_value NUMERIC(10, 2) DEFAULT 0.00;
ALTER TABLE public.coupons ADD COLUMN IF NOT EXISTS discount_percent NUMERIC(5, 2) DEFAULT 0.00;
ALTER TABLE public.coupons ADD COLUMN IF NOT EXISTS min_order_amount NUMERIC(10, 2) DEFAULT 0.00;
ALTER TABLE public.coupons ADD COLUMN IF NOT EXISTS max_discount NUMERIC(10, 2);
ALTER TABLE public.coupons ADD COLUMN IF NOT EXISTS usage_limit INT;
ALTER TABLE public.coupons ADD COLUMN IF NOT EXISTS usage_count INT DEFAULT 0;
ALTER TABLE public.coupons ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;
ALTER TABLE public.coupons ADD COLUMN IF NOT EXISTS expires_at TIMESTAMPTZ;

-- ==============================================================================
-- ⭐ RATINGS & REVIEWS TABLE (Target-scoped)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.ratings (
    id TEXT PRIMARY KEY,
    target_id TEXT NOT NULL,
    target_type TEXT NOT NULL CHECK (target_type IN ('menuItem', 'driver', 'restaurant')),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    user_name TEXT,
    score NUMERIC(2, 1) NOT NULL CHECK (score >= 1.0 AND score <= 5.0),
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.ratings ADD COLUMN IF NOT EXISTS target_id TEXT;
ALTER TABLE public.ratings ADD COLUMN IF NOT EXISTS target_type TEXT DEFAULT 'menuItem';
ALTER TABLE public.ratings ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.ratings ADD COLUMN IF NOT EXISTS user_name TEXT;
ALTER TABLE public.ratings ADD COLUMN IF NOT EXISTS score NUMERIC(2, 1) DEFAULT 5.0;
ALTER TABLE public.ratings ADD COLUMN IF NOT EXISTS comment TEXT;
ALTER TABLE public.ratings ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();

-- ==============================================================================
-- 📦 INVENTORY TABLE
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.inventory (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    quantity NUMERIC(10, 2) NOT NULL DEFAULT 0,
    unit TEXT NOT NULL,
    min_threshold NUMERIC(10, 2) NOT NULL DEFAULT 5,
    cost_per_unit NUMERIC(10, 2) DEFAULT 0.00,
    last_updated TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.inventory ADD COLUMN IF NOT EXISTS name TEXT;
ALTER TABLE public.inventory ADD COLUMN IF NOT EXISTS category TEXT;
ALTER TABLE public.inventory ADD COLUMN IF NOT EXISTS quantity NUMERIC(10, 2) DEFAULT 0;
ALTER TABLE public.inventory ADD COLUMN IF NOT EXISTS unit TEXT;
ALTER TABLE public.inventory ADD COLUMN IF NOT EXISTS min_threshold NUMERIC(10, 2) DEFAULT 5;
ALTER TABLE public.inventory ADD COLUMN IF NOT EXISTS cost_per_unit NUMERIC(10, 2) DEFAULT 0.00;
ALTER TABLE public.inventory ADD COLUMN IF NOT EXISTS last_updated TIMESTAMPTZ DEFAULT NOW();

-- ==============================================================================
-- 🎁 LOYALTY TABLES
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.loyalty_accounts (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    current_points INT NOT NULL DEFAULT 0,
    lifetime_points INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.loyalty_accounts ADD COLUMN IF NOT EXISTS current_points INT DEFAULT 0;
ALTER TABLE public.loyalty_accounts ADD COLUMN IF NOT EXISTS lifetime_points INT DEFAULT 0;

CREATE TABLE IF NOT EXISTS public.loyalty_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    points INT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('earn', 'redeem', 'bonus')),
    description TEXT,
    order_id TEXT UNIQUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.loyalty_rewards (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    points_cost INT NOT NULL,
    discount_amount NUMERIC(10, 2) NOT NULL,
    min_order_amount NUMERIC(10, 2) DEFAULT 0.00,
    icon_name TEXT DEFAULT 'card_giftcard',
    is_active BOOLEAN DEFAULT TRUE
);

-- ==============================================================================
-- 🔒 HELPER SECURITY FUNCTIONS
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role FROM public.profiles WHERE id::text = auth.uid()::text LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.is_staff()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.get_my_role() IN ('waiter', 'kitchen', 'manager', 'admin', 'driver', 'cashier');
$$;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.get_my_role() IN ('manager', 'admin');
$$;

-- ==============================================================================
-- 🔄 AUTOMATIC USER PROFILE TRIGGER & ROLE PROTECTION
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, name, email, phone, role)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'name', 'مستخدم جديد'),
    new.email,
    COALESCE(new.raw_user_meta_data->>'phone', new.phone),
    'customer'
  )
  ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    phone = EXCLUDED.phone,
    updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

CREATE OR REPLACE FUNCTION public.enforce_profile_insert_role()
RETURNS trigger AS $$
BEGIN
  IF NOT public.is_admin() THEN
    NEW.role := 'customer';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_enforce_profile_insert_role ON public.profiles;
CREATE TRIGGER trg_enforce_profile_insert_role
  BEFORE INSERT ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.enforce_profile_insert_role();

CREATE OR REPLACE FUNCTION public.enforce_profile_update_role()
RETURNS trigger AS $$
BEGIN
  IF NEW.role IS DISTINCT FROM OLD.role AND NOT public.is_admin() THEN
    NEW.role := OLD.role;
  END IF;
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_enforce_profile_update_role ON public.profiles;
CREATE TRIGGER trg_enforce_profile_update_role
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.enforce_profile_update_role();

-- ==============================================================================
-- 🎁 LOYALTY RPCs
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.earn_loyalty_points(p_order_id TEXT)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_order RECORD;
  v_account RECORD;
  v_multiplier NUMERIC := 1.0;
  v_points_earned INT;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'يجب تسجيل الدخول لاكتساب النقاط';
  END IF;

  SELECT * INTO v_order FROM public.orders WHERE id = p_order_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'الطلب غير موجود';
  END IF;

  IF v_order.customer_id IS DISTINCT FROM v_uid::text AND NOT public.is_staff() THEN
    RAISE EXCEPTION 'غير مصرح لك باكتساب نقاط هذا الطلب';
  END IF;

  IF v_order.status NOT IN ('completed', 'served', 'delivered') THEN
    RAISE EXCEPTION 'لا يمكن اكتساب النقاط إلا بعد اكتمال الطلب';
  END IF;

  IF EXISTS (SELECT 1 FROM public.loyalty_transactions WHERE order_id = p_order_id) THEN
    SELECT * INTO v_account FROM public.loyalty_accounts WHERE user_id = v_uid;
    RETURN jsonb_build_object(
      'user_id', v_account.user_id,
      'current_points', v_account.current_points,
      'lifetime_points', v_account.lifetime_points,
      'already_earned', true
    );
  END IF;

  INSERT INTO public.loyalty_accounts (user_id, current_points, lifetime_points)
  VALUES (v_uid, 0, 0)
  ON CONFLICT (user_id) DO NOTHING;

  SELECT * INTO v_account FROM public.loyalty_accounts WHERE user_id = v_uid;

  IF v_account.lifetime_points >= 3000 THEN
    v_multiplier := 2.0;
  ELSIF v_account.lifetime_points >= 1500 THEN
    v_multiplier := 1.5;
  ELSIF v_account.lifetime_points >= 500 THEN
    v_multiplier := 1.25;
  ELSE
    v_multiplier := 1.0;
  END IF;

  v_points_earned := FLOOR(COALESCE(v_order.total_amount, 0) * v_multiplier);
  IF v_points_earned <= 0 THEN
    v_points_earned := 1;
  END IF;

  INSERT INTO public.loyalty_transactions (user_id, points, type, description, order_id)
  VALUES (v_uid, v_points_earned, 'earn', 'نقاط الطلب #' || p_order_id, p_order_id);

  UPDATE public.loyalty_accounts
  SET current_points = current_points + v_points_earned,
      lifetime_points = lifetime_points + v_points_earned,
      updated_at = NOW()
  WHERE user_id = v_uid
  RETURNING * INTO v_account;

  RETURN jsonb_build_object(
    'user_id', v_account.user_id,
    'current_points', v_account.current_points,
    'lifetime_points', v_account.lifetime_points,
    'points_earned', v_points_earned
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.redeem_loyalty_reward(p_reward_id TEXT)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_reward RECORD;
  v_account RECORD;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'يجب تسجيل الدخول لاستبدال المكافأة';
  END IF;

  SELECT * INTO v_reward FROM public.loyalty_rewards WHERE id = p_reward_id AND is_active = true;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'المكافأة غير متوفرة حالياً';
  END IF;

  SELECT * INTO v_account FROM public.loyalty_accounts WHERE user_id = v_uid;
  IF NOT FOUND OR v_account.current_points < v_reward.points_cost THEN
    RAISE EXCEPTION 'رصيد نقاطك غير كافٍ لاستبدال هذه المكافأة';
  END IF;

  INSERT INTO public.loyalty_transactions (user_id, points, type, description)
  VALUES (v_uid, -v_reward.points_cost, 'redeem', 'استبدال مكافأة: ' || v_reward.title);

  UPDATE public.loyalty_accounts
  SET current_points = current_points - v_reward.points_cost,
      updated_at = NOW()
  WHERE user_id = v_uid
  RETURNING * INTO v_account;

  RETURN jsonb_build_object(
    'user_id', v_account.user_id,
    'current_points', v_account.current_points,
    'lifetime_points', v_account.lifetime_points,
    'reward_title', v_reward.title,
    'discount_amount', v_reward.discount_amount
  );
END;
$$;

-- ==============================================================================
-- ⚡ REALTIME PUBLICATION & INDEXES
-- ==============================================================================
ALTER PUBLICATION supabase_realtime ADD TABLE public.orders;
ALTER PUBLICATION supabase_realtime ADD TABLE public.tables;
ALTER PUBLICATION supabase_realtime ADD TABLE public.driver_locations;
ALTER PUBLICATION supabase_realtime ADD TABLE public.menu_items;
ALTER PUBLICATION supabase_realtime ADD TABLE public.loyalty_accounts;
ALTER PUBLICATION supabase_realtime ADD TABLE public.reservations;
ALTER PUBLICATION supabase_realtime ADD TABLE public.coupons;

CREATE INDEX IF NOT EXISTS idx_orders_created_at ON public.orders (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON public.orders (customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders (status);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON public.order_items (order_id);
CREATE INDEX IF NOT EXISTS idx_driver_locations_driver_updated ON public.driver_locations (driver_id, updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_reservations_time ON public.reservations (reservation_time);
CREATE INDEX IF NOT EXISTS idx_ratings_target ON public.ratings (target_id, target_type);
CREATE INDEX IF NOT EXISTS idx_loyalty_transactions_user ON public.loyalty_transactions (user_id, created_at DESC);

-- ==============================================================================
-- 🔒 PRODUCTION ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu_modifier_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu_modifier_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tables ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.driver_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coupons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loyalty_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loyalty_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loyalty_rewards ENABLE ROW LEVEL SECURITY;

-- 1. Profiles
DROP POLICY IF EXISTS "profiles_select_policy" ON public.profiles;
CREATE POLICY "profiles_select_policy" ON public.profiles FOR SELECT USING (id::text = auth.uid()::text OR public.is_staff());

DROP POLICY IF EXISTS "profiles_insert_policy" ON public.profiles;
CREATE POLICY "profiles_insert_policy" ON public.profiles FOR INSERT WITH CHECK (id::text = auth.uid()::text);

DROP POLICY IF EXISTS "profiles_update_policy" ON public.profiles;
CREATE POLICY "profiles_update_policy" ON public.profiles FOR UPDATE USING (id::text = auth.uid()::text OR public.is_admin());

DROP POLICY IF EXISTS "profiles_delete_policy" ON public.profiles;
CREATE POLICY "profiles_delete_policy" ON public.profiles FOR DELETE USING (public.is_admin());

-- 2. Menu Catalog (Public Read, Admin Write)
DROP POLICY IF EXISTS "categories_select_policy" ON public.categories;
CREATE POLICY "categories_select_policy" ON public.categories FOR SELECT USING (true);

DROP POLICY IF EXISTS "categories_insert_policy" ON public.categories;
CREATE POLICY "categories_insert_policy" ON public.categories FOR INSERT WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "categories_update_policy" ON public.categories;
CREATE POLICY "categories_update_policy" ON public.categories FOR UPDATE USING (public.is_admin());

DROP POLICY IF EXISTS "categories_delete_policy" ON public.categories;
CREATE POLICY "categories_delete_policy" ON public.categories FOR DELETE USING (public.is_admin());

DROP POLICY IF EXISTS "menu_items_select_policy" ON public.menu_items;
CREATE POLICY "menu_items_select_policy" ON public.menu_items FOR SELECT USING (true);

DROP POLICY IF EXISTS "menu_items_insert_policy" ON public.menu_items;
CREATE POLICY "menu_items_insert_policy" ON public.menu_items FOR INSERT WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "menu_items_update_policy" ON public.menu_items;
CREATE POLICY "menu_items_update_policy" ON public.menu_items FOR UPDATE USING (public.is_admin());

DROP POLICY IF EXISTS "menu_items_delete_policy" ON public.menu_items;
CREATE POLICY "menu_items_delete_policy" ON public.menu_items FOR DELETE USING (public.is_admin());

DROP POLICY IF EXISTS "modifier_groups_select_policy" ON public.menu_modifier_groups;
CREATE POLICY "modifier_groups_select_policy" ON public.menu_modifier_groups FOR SELECT USING (true);

DROP POLICY IF EXISTS "modifier_groups_insert_policy" ON public.menu_modifier_groups;
CREATE POLICY "modifier_groups_insert_policy" ON public.menu_modifier_groups FOR INSERT WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "modifier_groups_update_policy" ON public.menu_modifier_groups;
CREATE POLICY "modifier_groups_update_policy" ON public.menu_modifier_groups FOR UPDATE USING (public.is_admin());

DROP POLICY IF EXISTS "modifier_groups_delete_policy" ON public.menu_modifier_groups;
CREATE POLICY "modifier_groups_delete_policy" ON public.menu_modifier_groups FOR DELETE USING (public.is_admin());

DROP POLICY IF EXISTS "modifier_options_select_policy" ON public.menu_modifier_options;
CREATE POLICY "modifier_options_select_policy" ON public.menu_modifier_options FOR SELECT USING (true);

DROP POLICY IF EXISTS "modifier_options_insert_policy" ON public.menu_modifier_options;
CREATE POLICY "modifier_options_insert_policy" ON public.menu_modifier_options FOR INSERT WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "modifier_options_update_policy" ON public.menu_modifier_options;
CREATE POLICY "modifier_options_update_policy" ON public.menu_modifier_options FOR UPDATE USING (public.is_admin());

DROP POLICY IF EXISTS "modifier_options_delete_policy" ON public.menu_modifier_options;
CREATE POLICY "modifier_options_delete_policy" ON public.menu_modifier_options FOR DELETE USING (public.is_admin());

-- 3. Tables
DROP POLICY IF EXISTS "tables_select_policy" ON public.tables;
CREATE POLICY "tables_select_policy" ON public.tables FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "tables_insert_policy" ON public.tables;
CREATE POLICY "tables_insert_policy" ON public.tables FOR INSERT WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "tables_update_policy" ON public.tables;
CREATE POLICY "tables_update_policy" ON public.tables FOR UPDATE USING (public.is_staff());

DROP POLICY IF EXISTS "tables_delete_policy" ON public.tables;
CREATE POLICY "tables_delete_policy" ON public.tables FOR DELETE USING (public.is_admin());

-- 4. Orders & Order Items
DROP POLICY IF EXISTS "orders_select_policy" ON public.orders;
CREATE POLICY "orders_select_policy" ON public.orders FOR SELECT USING (customer_id::text = auth.uid()::text OR public.is_staff());

DROP POLICY IF EXISTS "orders_insert_policy" ON public.orders;
CREATE POLICY "orders_insert_policy" ON public.orders FOR INSERT WITH CHECK (customer_id::text = auth.uid()::text OR public.is_staff());

DROP POLICY IF EXISTS "orders_update_policy" ON public.orders;
CREATE POLICY "orders_update_policy" ON public.orders FOR UPDATE USING (public.is_staff());

DROP POLICY IF EXISTS "orders_delete_policy" ON public.orders;
CREATE POLICY "orders_delete_policy" ON public.orders FOR DELETE USING (public.is_admin());

DROP POLICY IF EXISTS "order_items_select_policy" ON public.order_items;
CREATE POLICY "order_items_select_policy" ON public.order_items FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.orders o
    WHERE o.id::text = order_items.order_id::text
    AND (o.customer_id::text = auth.uid()::text OR public.is_staff())
  )
);

DROP POLICY IF EXISTS "order_items_insert_policy" ON public.order_items;
CREATE POLICY "order_items_insert_policy" ON public.order_items FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.orders o
    WHERE o.id::text = order_items.order_id::text
    AND (o.customer_id::text = auth.uid()::text OR public.is_staff())
  )
);

DROP POLICY IF EXISTS "order_items_update_policy" ON public.order_items;
CREATE POLICY "order_items_update_policy" ON public.order_items FOR UPDATE USING (public.is_staff());

DROP POLICY IF EXISTS "order_items_delete_policy" ON public.order_items;
CREATE POLICY "order_items_delete_policy" ON public.order_items FOR DELETE USING (public.is_admin());

-- 5. Driver Locations
DROP POLICY IF EXISTS "driver_locations_select_policy" ON public.driver_locations;
CREATE POLICY "driver_locations_select_policy" ON public.driver_locations FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "driver_locations_insert_policy" ON public.driver_locations;
CREATE POLICY "driver_locations_insert_policy" ON public.driver_locations FOR INSERT WITH CHECK (driver_id::text = auth.uid()::text OR public.is_staff());

DROP POLICY IF EXISTS "driver_locations_update_policy" ON public.driver_locations;
CREATE POLICY "driver_locations_update_policy" ON public.driver_locations FOR UPDATE USING (driver_id::text = auth.uid()::text OR public.is_staff());

DROP POLICY IF EXISTS "driver_locations_delete_policy" ON public.driver_locations;
CREATE POLICY "driver_locations_delete_policy" ON public.driver_locations FOR DELETE USING (public.is_admin());

-- 6. Reservations
DROP POLICY IF EXISTS "reservations_select_policy" ON public.reservations;
CREATE POLICY "reservations_select_policy" ON public.reservations FOR SELECT USING (user_id::text = auth.uid()::text OR public.is_staff());

DROP POLICY IF EXISTS "reservations_insert_policy" ON public.reservations;
CREATE POLICY "reservations_insert_policy" ON public.reservations FOR INSERT WITH CHECK (auth.role() = 'authenticated' AND (user_id::text = auth.uid()::text OR public.is_staff()));

DROP POLICY IF EXISTS "reservations_update_policy" ON public.reservations;
CREATE POLICY "reservations_update_policy" ON public.reservations FOR UPDATE USING (public.is_staff());

DROP POLICY IF EXISTS "reservations_delete_policy" ON public.reservations;
CREATE POLICY "reservations_delete_policy" ON public.reservations FOR DELETE USING (public.is_admin());

-- 7. Coupons
DROP POLICY IF EXISTS "coupons_select_policy" ON public.coupons;
CREATE POLICY "coupons_select_policy" ON public.coupons FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "coupons_insert_policy" ON public.coupons;
CREATE POLICY "coupons_insert_policy" ON public.coupons FOR INSERT WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "coupons_update_policy" ON public.coupons;
CREATE POLICY "coupons_update_policy" ON public.coupons FOR UPDATE USING (public.is_admin());

DROP POLICY IF EXISTS "coupons_delete_policy" ON public.coupons;
CREATE POLICY "coupons_delete_policy" ON public.coupons FOR DELETE USING (public.is_admin());

-- 8. Ratings
DROP POLICY IF EXISTS "ratings_select_policy" ON public.ratings;
CREATE POLICY "ratings_select_policy" ON public.ratings FOR SELECT USING (true);

DROP POLICY IF EXISTS "ratings_insert_policy" ON public.ratings;
CREATE POLICY "ratings_insert_policy" ON public.ratings FOR INSERT WITH CHECK (auth.role() = 'authenticated' AND user_id::text = auth.uid()::text AND score >= 1.0 AND score <= 5.0);

DROP POLICY IF EXISTS "ratings_update_policy" ON public.ratings;
CREATE POLICY "ratings_update_policy" ON public.ratings FOR UPDATE USING (user_id::text = auth.uid()::text);

DROP POLICY IF EXISTS "ratings_delete_policy" ON public.ratings;
CREATE POLICY "ratings_delete_policy" ON public.ratings FOR DELETE USING (public.is_admin());

-- 9. Inventory
DROP POLICY IF EXISTS "inventory_select_policy" ON public.inventory;
CREATE POLICY "inventory_select_policy" ON public.inventory FOR SELECT USING (public.is_staff());

DROP POLICY IF EXISTS "inventory_insert_policy" ON public.inventory;
CREATE POLICY "inventory_insert_policy" ON public.inventory FOR INSERT WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "inventory_update_policy" ON public.inventory;
CREATE POLICY "inventory_update_policy" ON public.inventory FOR UPDATE USING (public.is_admin());

DROP POLICY IF EXISTS "inventory_delete_policy" ON public.inventory;
CREATE POLICY "inventory_delete_policy" ON public.inventory FOR DELETE USING (public.is_admin());

-- 10. Loyalty
DROP POLICY IF EXISTS "loyalty_accounts_select_policy" ON public.loyalty_accounts;
CREATE POLICY "loyalty_accounts_select_policy" ON public.loyalty_accounts FOR SELECT USING (user_id::text = auth.uid()::text OR public.is_staff());

DROP POLICY IF EXISTS "loyalty_accounts_update_policy" ON public.loyalty_accounts;
CREATE POLICY "loyalty_accounts_update_policy" ON public.loyalty_accounts FOR UPDATE USING (public.is_admin());

DROP POLICY IF EXISTS "loyalty_transactions_select_policy" ON public.loyalty_transactions;
CREATE POLICY "loyalty_transactions_select_policy" ON public.loyalty_transactions FOR SELECT USING (user_id::text = auth.uid()::text OR public.is_staff());

DROP POLICY IF EXISTS "loyalty_rewards_select_policy" ON public.loyalty_rewards;
CREATE POLICY "loyalty_rewards_select_policy" ON public.loyalty_rewards FOR SELECT USING (true);

DROP POLICY IF EXISTS "loyalty_rewards_admin_policy" ON public.loyalty_rewards;
CREATE POLICY "loyalty_rewards_admin_policy" ON public.loyalty_rewards FOR ALL USING (public.is_admin());

-- ==============================================================================
-- 🗄️ STORAGE BUCKETS & POLICIES
-- ==============================================================================
INSERT INTO storage.buckets (id, name, public)
VALUES 
  ('menu-images', 'menu-images', true),
  ('user-avatars', 'user-avatars', false),
  ('delivery-proofs', 'delivery-proofs', false)
ON CONFLICT (id) DO UPDATE SET public = EXCLUDED.public;

DROP POLICY IF EXISTS "menu_images_public_read" ON storage.objects;
CREATE POLICY "menu_images_public_read" ON storage.objects
  FOR SELECT USING (bucket_id = 'menu-images');

DROP POLICY IF EXISTS "menu_images_admin_write" ON storage.objects;
CREATE POLICY "menu_images_admin_write" ON storage.objects
  FOR ALL USING (bucket_id = 'menu-images' AND public.is_admin())
  WITH CHECK (bucket_id = 'menu-images' AND public.is_admin());

DROP POLICY IF EXISTS "avatars_owner_select" ON storage.objects;
CREATE POLICY "avatars_owner_select" ON storage.objects
  FOR SELECT USING (bucket_id = 'user-avatars' AND ((storage.foldername(name))[1] = auth.uid()::text OR public.is_staff()));

DROP POLICY IF EXISTS "avatars_owner_insert" ON storage.objects;
CREATE POLICY "avatars_owner_insert" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'user-avatars' AND (storage.foldername(name))[1] = auth.uid()::text);

DROP POLICY IF EXISTS "avatars_owner_update" ON storage.objects;
CREATE POLICY "avatars_owner_update" ON storage.objects
  FOR UPDATE USING (bucket_id = 'user-avatars' AND (storage.foldername(name))[1] = auth.uid()::text);

DROP POLICY IF EXISTS "delivery_proofs_select" ON storage.objects;
CREATE POLICY "delivery_proofs_select" ON storage.objects
  FOR SELECT USING (bucket_id = 'delivery-proofs' AND public.is_staff());

DROP POLICY IF EXISTS "delivery_proofs_insert" ON storage.objects;
CREATE POLICY "delivery_proofs_insert" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'delivery-proofs' AND (public.is_staff() OR auth.role() = 'authenticated'));

-- ==============================================================================
-- 🚀 SEED DATA (الأقسام، الوجبات المصرية الأصيلة، الطاولات، الكوبونات، والمخزون)
-- ==============================================================================

-- 1. Categories
INSERT INTO public.categories (name, name_ar, icon, sort_order) VALUES
('مشويات', 'مشويات', 'flame', 1),
('طواجن', 'طواجن', 'pot', 2),
('مقبلات', 'مقبلات', 'salad', 3),
('مشروبات', 'مشروبات', 'glass', 4),
('حلويات', 'حلويات', 'cake', 5)
ON CONFLICT (name) DO NOTHING;

-- 2. Menu Items
INSERT INTO public.menu_items (id, restaurant_id, category_id, name, description, price, is_available, is_vegetarian, is_spicy, preparation_time, rating) VALUES
('item-1', 'restaurant-1', 'مشويات', 'كباب وكفتة ضاني', 'مشويات على الفحم مع أرز بسمتي وسلطات وطحينة', 280.00, true, false, false, 25, 4.9),
('item-2', 'restaurant-1', 'مشويات', 'شيش طاووق متبل', 'قطع صدور دجاج مشوية بتتبيلة الزعفران والليمون', 190.00, true, false, false, 20, 4.8),
('item-3', 'restaurant-1', 'طواجن', 'طاجن ملوخية بالفراخ', 'ملوخية خضراء مصرية بالطشة مع نصف دجاجة محمرة وأرز', 160.00, true, false, false, 15, 4.9),
('item-4', 'restaurant-1', 'طواجن', 'طاجن بامية باللحمة الضاني', 'طاجن بامية بلدي مع لحم ضاني مسبك في الفرن', 240.00, true, false, true, 20, 4.7),
('item-5', 'restaurant-1', 'مقبلات', 'شوربة لسان عصفور', 'شوربة غنية بالمرقة مع ليمون طازج', 45.00, true, false, false, 10, 4.6),
('item-6', 'restaurant-1', 'مقبلات', 'سلطة خضراء وطحينة بلدي', 'تشكيلة سلطة بلدي متبلة مع سلطة طحينة بالخل والكمون', 35.00, true, true, false, 5, 4.8),
('item-7', 'restaurant-1', 'مشروبات', 'عصير قصب طازج', 'عصير قصب طبيعي 100% مثلج', 30.00, true, true, false, 5, 4.9),
('item-8', 'restaurant-1', 'مشروبات', 'كركديه أسواني مثلج', 'كركديه منعش محلى بالسكر الطبيعي', 35.00, true, true, false, 5, 4.8),
('item-9', 'restaurant-1', 'حلويات', 'أم علي بالمكسرات والقشطة', 'أم علي ساخنة محمرة بالفرن مع القشطة والمكسرات', 75.00, true, true, false, 15, 4.9)
ON CONFLICT (id) DO UPDATE SET
  restaurant_id = EXCLUDED.restaurant_id,
  name = EXCLUDED.name,
  price = EXCLUDED.price;

-- 3. Tables
INSERT INTO public.tables (id, table_number, capacity, location, status) VALUES
('t1', 1, 2, 'تراس', 'available'),
('t2', 2, 4, 'صالة', 'available'),
('t3', 3, 4, 'صالة', 'occupied'),
('t4', 4, 6, 'حديقة', 'available'),
('t5', 5, 6, 'حديقة', 'reserved'),
('t6', 6, 8, 'قاعة', 'needsCleaning'),
('t7', 7, 2, 'تراس', 'available'),
('t8', 8, 4, 'صالة', 'occupied')
ON CONFLICT (id) DO NOTHING;

-- 4. Coupons
INSERT INTO public.coupons (id, code, title, discount_type, discount_value, discount_percent, max_discount, min_order_amount, is_active) VALUES
('c1', 'WELCOME10', 'خصم الترحيب 10%', 'percentage', 10.00, 10.00, 50.00, 40.00, true),
('c2', 'RAMADAN20', 'خصم رمضان 20%', 'percentage', 20.00, 20.00, 100.00, 60.00, true)
ON CONFLICT (id) DO NOTHING;

-- 5. Inventory Items
INSERT INTO public.inventory (id, name, category, quantity, unit, min_threshold, cost_per_unit) VALUES
('inv-1', 'لحم ضاني مفروم', 'لحوم', 25.0, 'كجم', 5.0, 380.00),
('inv-2', 'صدور دجاج', 'دواجن', 40.0, 'كجم', 8.0, 125.00),
('inv-3', 'أرز بسمتي فاخر', 'حبوب', 50.0, 'كجم', 10.0, 32.00),
('inv-4', 'ملوخية خضراء', 'خضروات', 15.0, 'كجم', 3.0, 20.00),
('inv-5', 'طحينة سمسم نقي', 'بقالة', 20.0, 'كجم', 4.0, 110.00)
ON CONFLICT (id) DO NOTHING;

-- 6. Loyalty Rewards
INSERT INTO public.loyalty_rewards (id, title, description, points_cost, discount_amount, min_order_amount, icon_name, is_active) VALUES
('rew-10', 'خصم 10 ريال فوري', 'خصم مباشر 10 ريال على أي طلب بقيمة 50 ريال أو أكثر', 100, 10.00, 50.00, 'local_offer', true),
('rew-25', 'خصم 25 ريال VIP', 'خصم 25 ريال على طلبات العشاء والولائم فوق 100 ريال', 220, 25.00, 100.00, 'stars', true),
('rew-50', 'وجبة مجانية / خصم 50 ريال', 'قسيمة خصم بقيمة 50 ريال صالحة على جميع الأصناف بدون حد أدنى', 400, 50.00, 0.00, 'restaurant', true),
('rew-100', 'قسيمة النخبة 100 ريال', 'أعلى مكافأة ولاء - خصم 100 ريال فوري لأعضاء الفئات الذهبية والبلاتينية', 750, 100.00, 0.00, 'workspace_premium', true)
ON CONFLICT (id) DO NOTHING;

-- ==============================================================================
-- 📡 REALTIME REPLICATION
-- ==============================================================================
DO $$
BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.orders;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.tables;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.driver_locations;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.reservations;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
END $$;
