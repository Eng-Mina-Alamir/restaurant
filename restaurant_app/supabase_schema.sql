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
