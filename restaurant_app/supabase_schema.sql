-- ==============================================================================
-- mikhael version please don't play on it
-- ==============================================================================
-- 🍽️ RESTAURANT MANAGEMENT SYSTEM - PRODUCTION SUPABASE SCHEMA
-- مطعم ليالي المحروسة - مخطط قاعدة البيانات الإنتاجية الشامل والمؤمن بالكامل
-- Updated with complete foreign keys, standardized data types, and covering indexes
-- ==============================================================================
-- 1. Enable Required Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==============================================================================
-- 🏬 RESTAURANTS TABLE (Base Tenant Entity)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.restaurants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR NOT NULL,
    address TEXT NOT NULL,
    phone VARCHAR NOT NULL,
    latitude DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    longitude DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    logo_url TEXT,
    open_time VARCHAR NOT NULL DEFAULT '10:00',
    close_time VARCHAR NOT NULL DEFAULT '23:00',
    total_tables INT NOT NULL DEFAULT 0,
    admin_id UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==============================================================================
-- 👤 PROFILES TABLE (Linked with Supabase Auth)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    restaurant_id UUID NOT NULL REFERENCES public.restaurants(id) ON DELETE CASCADE,
    name TEXT NOT NULL DEFAULT 'مستخدم جديد',
    email TEXT,
    phone TEXT,
    role TEXT NOT NULL DEFAULT 'customer' CHECK (role IN ('customer', 'waiter', 'kitchen', 'manager', 'driver', 'cashier', 'admin')),
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Circular FK for restaurant admin
ALTER TABLE public.restaurants
    DROP CONSTRAINT IF EXISTS restaurants_admin_id_fkey,
    ADD CONSTRAINT restaurants_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.profiles(id) ON DELETE SET NULL;

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
    restaurant_id UUID NOT NULL DEFAULT '1e08b47c-15be-4604-a913-431af7fbd54f'::uuid REFERENCES public.restaurants(id) ON DELETE CASCADE,
    category_id TEXT NOT NULL REFERENCES public.categories(name) ON UPDATE CASCADE ON DELETE RESTRICT,
    name VARCHAR NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    price NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    image_url TEXT,
    is_available BOOLEAN NOT NULL DEFAULT TRUE,
    is_vegetarian BOOLEAN NOT NULL DEFAULT FALSE,
    is_spicy BOOLEAN NOT NULL DEFAULT FALSE,
    preparation_time DOUBLE PRECISION DEFAULT 15.0,
    rating DOUBLE PRECISION DEFAULT 5.0,
    order_count INT DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

-- ==============================================================================
-- 🍟 MENU MODIFIER GROUPS & OPTIONS
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.menu_modifier_groups (
    id TEXT PRIMARY KEY,
    menu_item_id TEXT NOT NULL REFERENCES public.menu_items(id) ON DELETE CASCADE,
    title VARCHAR NOT NULL,
    description TEXT,
    is_required BOOLEAN NOT NULL DEFAULT FALSE,
    max_selection INT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.menu_modifier_options (
    id TEXT PRIMARY KEY,
    modifier_group_id TEXT NOT NULL REFERENCES public.menu_modifier_groups(id) ON DELETE CASCADE,
    name VARCHAR NOT NULL,
    extra_price NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    is_available BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==============================================================================
-- 🪑 DINING TABLES
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.tables (
    id TEXT PRIMARY KEY,
    table_number INT NOT NULL UNIQUE,
    capacity INT NOT NULL DEFAULT 4,
    location TEXT NOT NULL DEFAULT 'صالة',
    status TEXT NOT NULL DEFAULT 'available' CHECK (status IN ('available', 'occupied', 'reserved', 'needsCleaning')),
    current_order_id TEXT,
    assigned_waiter_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    last_updated TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 🧾 ORDERS TABLE
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.orders (
    id TEXT PRIMARY KEY,
    restaurant_id UUID NOT NULL DEFAULT '1e08b47c-15be-4604-a913-431af7fbd54f'::uuid REFERENCES public.restaurants(id) ON DELETE CASCADE,
    customer_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    table_id TEXT REFERENCES public.tables(id) ON DELETE SET NULL,
    waiter_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    order_type VARCHAR NOT NULL DEFAULT 'dineIn' CHECK (order_type IN ('dineIn', 'takeaway', 'delivery')),
    status VARCHAR NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'preparing', 'ready', 'served', 'completed', 'cancelled', 'delivering', 'delivered', 'rejected')),
    subtotal NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    tax_amount NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    discount_amount NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    total_amount NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    payment_method VARCHAR,
    delivery_address TEXT,
    delivery_notes TEXT,
    estimated_minutes INT DEFAULT 20,
    items_json JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==============================================================================
-- 📦 ORDER ITEMS TABLE (Line Items)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.order_items (
    id BIGSERIAL PRIMARY KEY,
    order_id TEXT NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    menu_item_id TEXT REFERENCES public.menu_items(id) ON DELETE SET NULL,
    item_name VARCHAR NOT NULL,
    price NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    quantity INT NOT NULL DEFAULT 1,
    total_price NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    special_notes TEXT,
    modifiers_json JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==============================================================================
-- 📅 RESERVATIONS TABLE
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.reservations (
    id TEXT PRIMARY KEY,
    restaurant_id UUID NOT NULL DEFAULT '1e08b47c-15be-4604-a913-431af7fbd54f'::uuid REFERENCES public.restaurants(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    customer_name VARCHAR NOT NULL,
    phone VARCHAR NOT NULL,
    party_size INT NOT NULL DEFAULT 2,
    reservation_date DATE,
    reservation_time TIMESTAMPTZ NOT NULL,
    duration_minutes INT DEFAULT 90,
    table_id TEXT REFERENCES public.tables(id) ON DELETE SET NULL,
    table_number INT,
    status VARCHAR NOT NULL DEFAULT 'confirmed' CHECK (status IN ('pending', 'confirmed', 'seated', 'cancelled', 'completed')),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==============================================================================
-- 🏷️ COUPONS TABLE
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.coupons (
    id TEXT PRIMARY KEY,
    code VARCHAR NOT NULL UNIQUE,
    title TEXT,
    discount_type VARCHAR NOT NULL DEFAULT 'percentage' CHECK (discount_type IN ('percentage', 'fixed')),
    discount_value NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    discount_percent NUMERIC(5, 2) DEFAULT 0.00,
    min_order_amount NUMERIC(10, 2) DEFAULT 0.00,
    max_discount NUMERIC(10, 2),
    usage_limit INT,
    usage_count INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    expires_at TIMESTAMPTZ
);

-- ==============================================================================
-- ⭐ RATINGS & REVIEWS TABLE
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.ratings (
    id TEXT PRIMARY KEY,
    target_id TEXT NOT NULL,
    target_type TEXT NOT NULL CHECK (target_type IN ('menuItem', 'driver', 'restaurant')),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    user_name TEXT,
    score NUMERIC(2, 1) NOT NULL CHECK (score >= 1.0 AND score <= 5.0),
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 📦 INVENTORY TABLE
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.inventory (
    id TEXT PRIMARY KEY,
    restaurant_id UUID NOT NULL DEFAULT '1e08b47c-15be-4604-a913-431af7fbd54f'::uuid REFERENCES public.restaurants(id) ON DELETE CASCADE,
    name VARCHAR NOT NULL,
    category TEXT NOT NULL,
    quantity NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    unit VARCHAR NOT NULL DEFAULT 'كجم',
    min_threshold NUMERIC(10, 2) NOT NULL DEFAULT 5.00,
    cost_per_unit NUMERIC(10, 2) DEFAULT 0.00,
    supplier_name VARCHAR,
    supplier_contact VARCHAR,
    last_updated TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 📍 DRIVER LOCATIONS (Realtime GPS Tracking)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.driver_locations (
    id BIGSERIAL PRIMARY KEY,
    driver_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    order_id TEXT REFERENCES public.orders(id) ON DELETE SET NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 🎁 LOYALTY TABLES
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.loyalty_accounts (
    user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    current_points INT NOT NULL DEFAULT 0,
    lifetime_points INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.loyalty_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    points INT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('earn', 'redeem', 'bonus')),
    description TEXT,
    order_id TEXT REFERENCES public.orders(id) ON DELETE SET NULL,
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
-- 🔍 COVERING INDEXES
-- ==============================================================================
CREATE INDEX IF NOT EXISTS idx_restaurants_admin_id ON public.restaurants(admin_id);
CREATE INDEX IF NOT EXISTS idx_profiles_restaurant_id ON public.profiles(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_menu_items_restaurant_id ON public.menu_items(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_menu_items_category_id ON public.menu_items(category_id);
CREATE INDEX IF NOT EXISTS idx_menu_modifier_groups_menu_item_id ON public.menu_modifier_groups(menu_item_id);
CREATE INDEX IF NOT EXISTS idx_menu_modifier_options_modifier_group_id ON public.menu_modifier_options(modifier_group_id);
CREATE INDEX IF NOT EXISTS idx_tables_assigned_waiter ON public.tables(assigned_waiter_id);
CREATE INDEX IF NOT EXISTS idx_orders_restaurant_id ON public.orders(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON public.orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_waiter_id ON public.orders(waiter_id);
CREATE INDEX IF NOT EXISTS idx_orders_table_id ON public.orders(table_id);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON public.order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_menu_item_id ON public.order_items(menu_item_id);
CREATE INDEX IF NOT EXISTS idx_reservations_restaurant_id ON public.reservations(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_reservations_user_id ON public.reservations(user_id);
CREATE INDEX IF NOT EXISTS idx_reservations_table_id ON public.reservations(table_id);
CREATE INDEX IF NOT EXISTS idx_ratings_user_id ON public.ratings(user_id);
CREATE INDEX IF NOT EXISTS idx_driver_locations_driver_id ON public.driver_locations(driver_id);
CREATE INDEX IF NOT EXISTS idx_driver_locations_order_id ON public.driver_locations(order_id);
CREATE INDEX IF NOT EXISTS idx_loyalty_transactions_user_id ON public.loyalty_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_loyalty_transactions_order_id ON public.loyalty_transactions(order_id);
CREATE INDEX IF NOT EXISTS idx_inventory_restaurant_id ON public.inventory(restaurant_id);

-- ==============================================================================
-- 🔐 ROW LEVEL SECURITY (RLS) — DENY-BY-DEFAULT HARDENING
-- ==============================================================================
-- Every public table is locked behind explicit policies. Roles are resolved
-- SERVER-SIDE from profiles.role (via auth.uid()) — client-supplied role
-- metadata is NEVER trusted. Without an explicit policy below, access is denied.
--
-- NOTE: apply inside a transaction wrapper in production (BEGIN; ... COMMIT;)
-- so a partial failure never leaves tables exposed.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 🧰 HELPER FUNCTIONS
-- SECURITY DEFINER lets policies read profiles.role WITHOUT triggering
-- recursive RLS evaluation on the profiles table itself.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.app_role()
RETURNS TEXT
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
    SELECT role FROM public.profiles WHERE id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.has_role(roles TEXT[])
RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
    SELECT COALESCE(
        (SELECT role FROM public.profiles WHERE id = auth.uid()) = ANY(roles),
        FALSE
    );
$$;

CREATE OR REPLACE FUNCTION public.is_staff()
RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
    SELECT public.has_role(ARRAY['waiter','kitchen','cashier','manager','admin','driver']::TEXT[]);
$$;

CREATE OR REPLACE FUNCTION public.is_kitchen()
RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
    SELECT public.has_role(ARRAY['kitchen']::TEXT[]);
$$;

CREATE OR REPLACE FUNCTION public.is_waiter_or_cashier()
RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
    SELECT public.has_role(ARRAY['waiter','cashier']::TEXT[]);
$$;

CREATE OR REPLACE FUNCTION public.is_manager_or_admin()
RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
    SELECT public.has_role(ARRAY['manager','admin']::TEXT[]);
$$;

-- Helpers expose no secrets but should not be callable pre-authentication.
REVOKE EXECUTE ON FUNCTION public.app_role() FROM anon;
REVOKE EXECUTE ON FUNCTION public.has_role(TEXT[]) FROM anon;
REVOKE EXECUTE ON FUNCTION public.is_staff() FROM anon;
REVOKE EXECUTE ON FUNCTION public.is_kitchen() FROM anon;
REVOKE EXECUTE ON FUNCTION public.is_waiter_or_cashier() FROM anon;
REVOKE EXECUTE ON FUNCTION public.is_manager_or_admin() FROM anon;

-- ------------------------------------------------------------------------------
-- 🛡️ PRIVILEGE-ESCALATION GUARDS
-- 1) profiles.role / restaurant_id cannot be self-minted: signups are forced to
--    'customer'; only existing managers/admins may provision privileged roles.
-- 2) Coupon redemptions (any authenticated user bumps usage_count) may never
--    mutate any OTHER coupon column.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.protect_profile_privileges()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NOT public.is_manager_or_admin() THEN
            NEW.role := 'customer';  -- self-signup downgrade
        END IF;
    ELSIF TG_OP = 'UPDATE' THEN
        IF NEW.role IS DISTINCT FROM OLD.role
           AND NOT public.is_manager_or_admin() THEN
            RAISE EXCEPTION 'Changing role requires manager or admin privileges';
        END IF;
        IF NEW.restaurant_id IS DISTINCT FROM OLD.restaurant_id
           AND NOT public.is_manager_or_admin() THEN
            RAISE EXCEPTION 'Changing restaurant_id requires manager or admin privileges';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_protect_profile_privileges ON public.profiles;
CREATE TRIGGER trg_protect_profile_privileges
    BEFORE INSERT OR UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.protect_profile_privileges();

CREATE OR REPLACE FUNCTION public.restrict_coupon_updates()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF NOT public.is_manager_or_admin() THEN
        IF (NEW.id, NEW.code, NEW.title, NEW.discount_type, NEW.discount_value,
            NEW.discount_percent, NEW.min_order_amount, NEW.max_discount,
            NEW.usage_limit, NEW.is_active, NEW.expires_at)
           IS DISTINCT FROM
           (OLD.id, OLD.code, OLD.title, OLD.discount_type, OLD.discount_value,
            OLD.discount_percent, OLD.min_order_amount, OLD.max_discount,
            OLD.usage_limit, OLD.is_active, OLD.expires_at) THEN
            RAISE EXCEPTION 'Non-managers may only modify usage_count';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_restrict_coupon_updates ON public.coupons;
CREATE TRIGGER trg_restrict_coupon_updates
    BEFORE UPDATE ON public.coupons
    FOR EACH ROW EXECUTE FUNCTION public.restrict_coupon_updates();

-- ------------------------------------------------------------------------------
-- 🏬 RESTAURANTS — public catalog info readable; mutations admin/manager only
-- ------------------------------------------------------------------------------
ALTER TABLE public.restaurants ENABLE ROW LEVEL SECURITY;
CREATE POLICY restaurants_select ON public.restaurants
    FOR SELECT USING (true);
CREATE POLICY restaurants_manage ON public.restaurants
    FOR ALL TO authenticated
    USING (public.is_manager_or_admin())
    WITH CHECK (public.is_manager_or_admin());

-- ------------------------------------------------------------------------------
-- 👤 PROFILES — self access + staff visibility; privilege columns guarded above
-- ------------------------------------------------------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY profiles_select ON public.profiles
    FOR SELECT TO authenticated
    USING (id = auth.uid() OR public.is_staff());
CREATE POLICY profiles_insert ON public.profiles
    FOR INSERT TO authenticated
    WITH CHECK (id = auth.uid() OR public.is_manager_or_admin());
CREATE POLICY profiles_update ON public.profiles
    FOR UPDATE TO authenticated
    USING (id = auth.uid() OR public.is_manager_or_admin())
    WITH CHECK (id = auth.uid() OR public.is_manager_or_admin());
CREATE POLICY profiles_delete ON public.profiles
    FOR DELETE TO authenticated
    USING (public.is_manager_or_admin());

-- ------------------------------------------------------------------------------
-- 📋 CATEGORIES — public menu structure; mutations manager/admin only
-- ------------------------------------------------------------------------------
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY categories_select ON public.categories
    FOR SELECT USING (true);
CREATE POLICY categories_manage ON public.categories
    FOR ALL TO authenticated
    USING (public.is_manager_or_admin())
    WITH CHECK (public.is_manager_or_admin());

-- ------------------------------------------------------------------------------
-- 🥘 MENU ITEMS — public catalog; kitchen may toggle availability, managers own CRUD
-- ------------------------------------------------------------------------------
ALTER TABLE public.menu_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY menu_items_select ON public.menu_items
    FOR SELECT USING (true);
CREATE POLICY menu_items_insert ON public.menu_items
    FOR INSERT TO authenticated
    WITH CHECK (public.is_manager_or_admin());
CREATE POLICY menu_items_update ON public.menu_items
    FOR UPDATE TO authenticated
    USING (public.is_manager_or_admin() OR public.is_kitchen())
    WITH CHECK (public.is_manager_or_admin() OR public.is_kitchen());
CREATE POLICY menu_items_delete ON public.menu_items
    FOR DELETE TO authenticated
    USING (public.is_manager_or_admin());

-- ------------------------------------------------------------------------------
-- 🍟 MODIFIER GROUPS & OPTIONS — follow menu item rules
-- ------------------------------------------------------------------------------
ALTER TABLE public.menu_modifier_groups ENABLE ROW LEVEL SECURITY;
CREATE POLICY modifier_groups_select ON public.menu_modifier_groups
    FOR SELECT USING (true);
CREATE POLICY modifier_groups_manage ON public.menu_modifier_groups
    FOR ALL TO authenticated
    USING (public.is_manager_or_admin() OR public.is_kitchen())
    WITH CHECK (public.is_manager_or_admin() OR public.is_kitchen());

ALTER TABLE public.menu_modifier_options ENABLE ROW LEVEL SECURITY;
CREATE POLICY modifier_options_select ON public.menu_modifier_options
    FOR SELECT USING (true);
CREATE POLICY modifier_options_manage ON public.menu_modifier_options
    FOR ALL TO authenticated
    USING (public.is_manager_or_admin() OR public.is_kitchen())
    WITH CHECK (public.is_manager_or_admin() OR public.is_kitchen());

-- ------------------------------------------------------------------------------
-- 🪑 DINING TABLES — floor state visible to signed-in users; staff mutate
-- ------------------------------------------------------------------------------
ALTER TABLE public.tables ENABLE ROW LEVEL SECURITY;
CREATE POLICY tables_select ON public.tables
    FOR SELECT TO authenticated
    USING (true);
CREATE POLICY tables_manage ON public.tables
    FOR ALL TO authenticated
    USING (public.is_waiter_or_cashier() OR public.is_manager_or_admin())
    WITH CHECK (public.is_waiter_or_cashier() OR public.is_manager_or_admin());

-- ------------------------------------------------------------------------------
-- 🧾 ORDERS — owners & assigned waiter read; staff progress states;
--    customers may touch only their own PENDING order (cancel/edit window);
--    drivers need broad read/update because orders carry no driver_id column.
-- ------------------------------------------------------------------------------
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY orders_select ON public.orders
    FOR SELECT TO authenticated
    USING (customer_id = auth.uid()
           OR waiter_id = auth.uid()
           OR public.is_staff());
CREATE POLICY orders_insert ON public.orders
    FOR INSERT TO authenticated
    WITH CHECK (customer_id = auth.uid()
                OR public.has_role(ARRAY['waiter','cashier','manager','admin']::TEXT[]));
CREATE POLICY orders_update_staff ON public.orders
    FOR UPDATE TO authenticated
    USING (public.is_staff())
    WITH CHECK (public.is_staff());
CREATE POLICY orders_update_owner_pending ON public.orders
    FOR UPDATE TO authenticated
    USING (customer_id = auth.uid() AND status = 'pending')
    WITH CHECK (customer_id = auth.uid());
CREATE POLICY orders_delete ON public.orders
    FOR DELETE TO authenticated
    USING (public.is_manager_or_admin());

-- ------------------------------------------------------------------------------
-- 📦 ORDER ITEMS — visibility inherited from the parent order
-- ------------------------------------------------------------------------------
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY order_items_select ON public.order_items
    FOR SELECT TO authenticated
    USING (EXISTS (
        SELECT 1 FROM public.orders o
        WHERE o.id = order_items.order_id
          AND (o.customer_id = auth.uid() OR o.waiter_id = auth.uid() OR public.is_staff())
    ));
CREATE POLICY order_items_write ON public.order_items
    FOR ALL TO authenticated
    USING (EXISTS (
        SELECT 1 FROM public.orders o
        WHERE o.id = order_items.order_id
          AND (o.customer_id = auth.uid() OR public.is_staff())
    ))
    WITH CHECK (EXISTS (
        SELECT 1 FROM public.orders o
        WHERE o.id = order_items.order_id
          AND (o.customer_id = auth.uid() OR public.is_staff())
    ));

-- ------------------------------------------------------------------------------
-- 📅 RESERVATIONS — guests manage their own; staff manage the book
-- ------------------------------------------------------------------------------
ALTER TABLE public.reservations ENABLE ROW LEVEL SECURITY;
CREATE POLICY reservations_select ON public.reservations
    FOR SELECT TO authenticated
    USING (user_id = auth.uid() OR public.is_staff());
CREATE POLICY reservations_insert ON public.reservations
    FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid()
                OR public.has_role(ARRAY['waiter','cashier','manager','admin']::TEXT[]));
CREATE POLICY reservations_update ON public.reservations
    FOR UPDATE TO authenticated
    USING (user_id = auth.uid() OR public.is_staff())
    WITH CHECK (user_id = auth.uid() OR public.is_staff());
CREATE POLICY reservations_delete ON public.reservations
    FOR DELETE TO authenticated
    USING (public.is_manager_or_admin());

-- ------------------------------------------------------------------------------
-- 🎟️ COUPONS — any signed-in user validates & redeems (usage_count only,
--    guarded by trigger); managers own the catalog
-- ------------------------------------------------------------------------------
ALTER TABLE public.coupons ENABLE ROW LEVEL SECURITY;
CREATE POLICY coupons_select ON public.coupons
    FOR SELECT TO authenticated
    USING (true);
CREATE POLICY coupons_redeem ON public.coupons
    FOR UPDATE TO authenticated
    USING (is_active = true)          -- redemption only touches live coupons;
    WITH CHECK (is_active = true);    -- column scope enforced by trg_restrict_coupon_updates
CREATE POLICY coupons_update ON public.coupons
    FOR UPDATE TO authenticated
    USING (public.is_manager_or_admin())
    WITH CHECK (public.is_manager_or_admin());
CREATE POLICY coupons_insert ON public.coupons
    FOR INSERT TO authenticated
    WITH CHECK (public.is_manager_or_admin());
CREATE POLICY coupons_delete ON public.coupons
    FOR DELETE TO authenticated
    USING (public.is_manager_or_admin());

-- ------------------------------------------------------------------------------
-- ⭐ RATINGS — community reviews; authors manage their own words
-- ------------------------------------------------------------------------------
ALTER TABLE public.ratings ENABLE ROW LEVEL SECURITY;
CREATE POLICY ratings_select ON public.ratings
    FOR SELECT TO authenticated
    USING (true);
CREATE POLICY ratings_insert ON public.ratings
    FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid());
CREATE POLICY ratings_update ON public.ratings
    FOR UPDATE TO authenticated
    USING (user_id = auth.uid() OR public.is_manager_or_admin())
    WITH CHECK (user_id = auth.uid() OR public.is_manager_or_admin());
CREATE POLICY ratings_delete ON public.ratings
    FOR DELETE TO authenticated
    USING (user_id = auth.uid() OR public.is_manager_or_admin());

-- ------------------------------------------------------------------------------
-- 📦 INVENTORY — cost/supplier data is commercial secret: staff-only read,
--    kitchen may adjust quantities, managers own CRUD
-- ------------------------------------------------------------------------------
ALTER TABLE public.inventory ENABLE ROW LEVEL SECURITY;
CREATE POLICY inventory_select ON public.inventory
    FOR SELECT TO authenticated
    USING (public.has_role(ARRAY['waiter','kitchen','cashier','manager','admin']::TEXT[]));
CREATE POLICY inventory_update ON public.inventory
    FOR UPDATE TO authenticated
    USING (public.is_manager_or_admin() OR public.is_kitchen())
    WITH CHECK (public.is_manager_or_admin() OR public.is_kitchen());
CREATE POLICY inventory_insert ON public.inventory
    FOR INSERT TO authenticated
    WITH CHECK (public.is_manager_or_admin());
CREATE POLICY inventory_delete ON public.inventory
    FOR DELETE TO authenticated
    USING (public.is_manager_or_admin());

-- ------------------------------------------------------------------------------
-- 📍 DRIVER LOCATIONS — live tracking feed shared with signed-in users;
--    a driver writes ONLY their own beacon
-- ------------------------------------------------------------------------------
ALTER TABLE public.driver_locations ENABLE ROW LEVEL SECURITY;
CREATE POLICY driver_locations_select ON public.driver_locations
    FOR SELECT TO authenticated
    USING (true);
CREATE POLICY driver_locations_insert ON public.driver_locations
    FOR INSERT TO authenticated
    WITH CHECK (driver_id = auth.uid());
CREATE POLICY driver_locations_update ON public.driver_locations
    FOR UPDATE TO authenticated
    USING (driver_id = auth.uid())
    WITH CHECK (driver_id = auth.uid());
CREATE POLICY driver_locations_delete ON public.driver_locations
    FOR DELETE TO authenticated
    USING (driver_id = auth.uid() OR public.is_manager_or_admin());

-- ------------------------------------------------------------------------------
-- 🎁 LOYALTY — members see/manage their own account & ledger; managers audit all
-- ------------------------------------------------------------------------------
ALTER TABLE public.loyalty_accounts ENABLE ROW LEVEL SECURITY;
CREATE POLICY loyalty_accounts_select ON public.loyalty_accounts
    FOR SELECT TO authenticated
    USING (user_id = auth.uid() OR public.is_manager_or_admin());
CREATE POLICY loyalty_accounts_insert ON public.loyalty_accounts
    FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid() OR public.is_manager_or_admin());
CREATE POLICY loyalty_accounts_update ON public.loyalty_accounts
    FOR UPDATE TO authenticated
    USING (user_id = auth.uid() OR public.is_manager_or_admin())
    WITH CHECK (user_id = auth.uid() OR public.is_manager_or_admin());
CREATE POLICY loyalty_accounts_delete ON public.loyalty_accounts
    FOR DELETE TO authenticated
    USING (public.is_manager_or_admin());

ALTER TABLE public.loyalty_transactions ENABLE ROW LEVEL SECURITY;
CREATE POLICY loyalty_transactions_select ON public.loyalty_transactions
    FOR SELECT TO authenticated
    USING (user_id = auth.uid() OR public.is_manager_or_admin());
CREATE POLICY loyalty_transactions_insert ON public.loyalty_transactions
    FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid() OR public.is_manager_or_admin());
CREATE POLICY loyalty_transactions_delete ON public.loyalty_transactions
    FOR DELETE TO authenticated
    USING (public.is_manager_or_admin());

ALTER TABLE public.loyalty_rewards ENABLE ROW LEVEL SECURITY;
CREATE POLICY loyalty_rewards_select ON public.loyalty_rewards
    FOR SELECT TO authenticated
    USING (true);
CREATE POLICY loyalty_rewards_manage ON public.loyalty_rewards
    FOR ALL TO authenticated
    USING (public.is_manager_or_admin())
    WITH CHECK (public.is_manager_or_admin());

-- ==============================================================================
-- 🚀 SCHEMA V3 — DELIVERY DISPATCH & ORDER STATUS AUDIT
-- ==============================================================================
-- Kitchen/driver assignment columns on orders, driver profile fields, the
-- delivery_assignments dispatch table, and the order_status_log audit trail.
-- Every statement below is idempotent; every new table ships with RLS enabled
-- and explicit deny-by-default policies built on the server-side role helpers.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 🧾 ORDERS — dispatch columns (assigned kitchen chef & delivery driver)
-- ------------------------------------------------------------------------------
ALTER TABLE public.orders
    ADD COLUMN IF NOT EXISTS assigned_kitchen_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS driver_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL;

-- ------------------------------------------------------------------------------
-- 👤 PROFILES — driver profile fields (availability, rating, vehicle)
-- ------------------------------------------------------------------------------
ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS is_available BOOLEAN NOT NULL DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS rating NUMERIC(2,1) NOT NULL DEFAULT 5.0,
    ADD COLUMN IF NOT EXISTS vehicle_info TEXT;

-- ------------------------------------------------------------------------------
-- 🚚 DELIVERY ASSIGNMENTS — links an order to its driver run;
--    drivers see & progress only their own assignments, staff dispatch inserts,
--    managers/admins control everything
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.delivery_assignments (
    id TEXT PRIMARY KEY,
    order_id TEXT NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    driver_id UUID NOT NULL REFERENCES public.profiles(id),
    pickup_time TIMESTAMPTZ,
    delivered_time TIMESTAMPTZ,
    delivery_location TEXT NOT NULL,
    customer_phone TEXT,
    latitude DOUBLE PRECISION DEFAULT 0,
    longitude DOUBLE PRECISION DEFAULT 0,
    delivery_status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (delivery_status IN ('pending', 'accepted', 'pickedUp', 'inTransit', 'delivered', 'failed')),
    delivery_fee NUMERIC(10, 2),
    route_distance_meters NUMERIC(12, 2),
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    assignment_method VARCHAR(10) DEFAULT 'auto' CHECK (assignment_method IN ('auto', 'manual'))
);

CREATE INDEX IF NOT EXISTS idx_delivery_assignments_order_id ON public.delivery_assignments(order_id);
CREATE INDEX IF NOT EXISTS idx_delivery_assignments_driver_id ON public.delivery_assignments(driver_id);

ALTER TABLE public.delivery_assignments ENABLE ROW LEVEL SECURITY;
CREATE POLICY delivery_assignments_select ON public.delivery_assignments
    FOR SELECT TO authenticated
    USING (driver_id = auth.uid() OR public.is_manager_or_admin());
CREATE POLICY delivery_assignments_update_driver ON public.delivery_assignments
    FOR UPDATE TO authenticated
    USING (driver_id = auth.uid())
    WITH CHECK (driver_id = auth.uid());
CREATE POLICY delivery_assignments_insert ON public.delivery_assignments
    FOR INSERT TO authenticated
    WITH CHECK (driver_id = auth.uid()
                OR public.has_role(ARRAY['waiter','kitchen','cashier','manager','admin']::TEXT[]));
CREATE POLICY delivery_assignments_manage ON public.delivery_assignments
    FOR ALL TO authenticated
    USING (public.is_manager_or_admin())
    WITH CHECK (public.is_manager_or_admin());

-- ------------------------------------------------------------------------------
-- 📜 ORDER STATUS LOG — audit trail of status transitions;
--    staff record changes, managers audit all, drivers/customers read the
--    history of orders they own
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.order_status_log (
    id BIGSERIAL PRIMARY KEY,
    order_id TEXT NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    from_status VARCHAR(20) NOT NULL,
    to_status VARCHAR(20) NOT NULL,
    changed_by UUID REFERENCES public.profiles(id),
    reason TEXT,
    is_revert BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_order_status_log_order_id ON public.order_status_log(order_id);

ALTER TABLE public.order_status_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY order_status_log_select ON public.order_status_log
    FOR SELECT TO authenticated
    USING (public.is_manager_or_admin()
           OR EXISTS (
               SELECT 1 FROM public.orders o
               WHERE o.id = order_status_log.order_id
                 AND o.customer_id = auth.uid()
           )
           OR EXISTS (
               SELECT 1 FROM public.delivery_assignments da
               WHERE da.order_id = order_status_log.order_id
                 AND da.driver_id = auth.uid()
           ));
CREATE POLICY order_status_log_insert ON public.order_status_log
    FOR INSERT TO authenticated
    WITH CHECK (public.has_role(ARRAY['waiter','kitchen','cashier','manager','admin']::TEXT[])
                AND changed_by = auth.uid());
