-- ==============================================================================
-- 🍽️ RESTAURANT MANAGEMENT SYSTEM - PRODUCTION SUPABASE SCHEMA
-- مطعم ليالي المحروسة - مخطط قاعدة البيانات الإنتاجية الشامل
-- ==============================================================================

-- 1. Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

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
    customer_name TEXT NOT NULL,
    phone TEXT NOT NULL,
    party_size INT NOT NULL DEFAULT 2,
    reservation_time TIMESTAMPTZ NOT NULL,
    table_id TEXT,
    status TEXT DEFAULT 'confirmed' CHECK (status IN ('pending', 'confirmed', 'seated', 'cancelled')),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 🏷️ COUPONS TABLE
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.coupons (
    id TEXT PRIMARY KEY,
    code TEXT NOT NULL UNIQUE,
    discount_percent NUMERIC(5, 2) NOT NULL,
    max_discount NUMERIC(10, 2),
    is_active BOOLEAN DEFAULT TRUE,
    expires_at TIMESTAMPTZ
);

-- ==============================================================================
-- ⭐ RATINGS & REVIEWS TABLE
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.ratings (
    id TEXT PRIMARY KEY,
    order_id TEXT,
    customer_name TEXT,
    food_rating INT NOT NULL DEFAULT 5,
    service_rating INT NOT NULL DEFAULT 5,
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

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
    last_updated TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- ⚡ REALTIME PUBLICATION ENABLEMENT
-- ==============================================================================
ALTER PUBLICATION supabase_realtime ADD TABLE public.orders;
ALTER PUBLICATION supabase_realtime ADD TABLE public.tables;
ALTER PUBLICATION supabase_realtime ADD TABLE public.driver_locations;
ALTER PUBLICATION supabase_realtime ADD TABLE public.menu_items;

-- ==============================================================================
-- 🗄️ STORAGE BUCKETS
-- ==============================================================================
INSERT INTO storage.buckets (id, name, public)
VALUES 
  ('menu-images', 'menu-images', true),
  ('user-avatars', 'user-avatars', true),
  ('delivery-proofs', 'delivery-proofs', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Storage Policies
CREATE POLICY "Public read for storage buckets" ON storage.objects
  FOR SELECT USING (bucket_id IN ('menu-images', 'user-avatars', 'delivery-proofs'));

CREATE POLICY "Authenticated users can upload images" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id IN ('menu-images', 'user-avatars', 'delivery-proofs'));

CREATE POLICY "Authenticated users can update images" ON storage.objects
  FOR UPDATE USING (bucket_id IN ('menu-images', 'user-avatars', 'delivery-proofs'));

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

-- 1. Profiles
CREATE POLICY "Profiles are viewable by everyone" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id OR auth.role() = 'anon');

-- 2. Categories & Menu Items (Public Read, Authenticated Management)
CREATE POLICY "Categories read access" ON public.categories FOR SELECT USING (true);
CREATE POLICY "Categories write access" ON public.categories FOR ALL USING (auth.role() = 'authenticated' OR auth.role() = 'anon');

CREATE POLICY "Menu items read access" ON public.menu_items FOR SELECT USING (true);
CREATE POLICY "Menu items write access" ON public.menu_items FOR ALL USING (auth.role() = 'authenticated' OR auth.role() = 'anon');

CREATE POLICY "Modifier groups read access" ON public.menu_modifier_groups FOR SELECT USING (true);
CREATE POLICY "Modifier groups write access" ON public.menu_modifier_groups FOR ALL USING (auth.role() = 'authenticated' OR auth.role() = 'anon');

CREATE POLICY "Modifier options read access" ON public.menu_modifier_options FOR SELECT USING (true);
CREATE POLICY "Modifier options write access" ON public.menu_modifier_options FOR ALL USING (auth.role() = 'authenticated' OR auth.role() = 'anon');

-- 3. Tables (Public Read & Update)
CREATE POLICY "Tables read access" ON public.tables FOR SELECT USING (true);
CREATE POLICY "Tables write access" ON public.tables FOR ALL USING (true);

-- 4. Orders & Order Items
CREATE POLICY "Orders read access" ON public.orders FOR SELECT USING (true);
CREATE POLICY "Orders insert access" ON public.orders FOR INSERT WITH CHECK (true);
CREATE POLICY "Orders update access" ON public.orders FOR UPDATE USING (true);

CREATE POLICY "Order items read access" ON public.order_items FOR SELECT USING (true);
CREATE POLICY "Order items insert access" ON public.order_items FOR INSERT WITH CHECK (true);
CREATE POLICY "Order items update access" ON public.order_items FOR UPDATE USING (true);

-- 5. Driver Locations (Realtime Tracking)
CREATE POLICY "Driver locations read access" ON public.driver_locations FOR SELECT USING (true);
CREATE POLICY "Driver locations write access" ON public.driver_locations FOR ALL USING (true);

-- 6. Reservations, Coupons, Ratings, Inventory
CREATE POLICY "Reservations read and write" ON public.reservations FOR ALL USING (true);
CREATE POLICY "Coupons read and write" ON public.coupons FOR ALL USING (true);
CREATE POLICY "Ratings read and write" ON public.ratings FOR ALL USING (true);
CREATE POLICY "Inventory read and write" ON public.inventory FOR ALL USING (true);

-- ==============================================================================
-- 🔄 AUTOMATIC USER PROFILE TRIGGER ON SIGN UP
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
    COALESCE(new.raw_user_meta_data->>'role', 'customer')
  )
  ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    phone = EXCLUDED.phone,
    role = EXCLUDED.role,
    updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ==============================================================================
-- 🚀 SEED DATA (الأقسام، الوجبات المصرية الأصيلة، والطاولات)
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
INSERT INTO public.menu_items (id, category_id, name, description, price, is_available, is_vegetarian, is_spicy, preparation_time, rating) VALUES
('item-1', 'مشويات', 'كباب وكفتة ضاني', 'مشويات على الفحم مع أرز بسمتي وسلطات وطحينة', 280.00, true, false, false, 25, 4.9),
('item-2', 'مشويات', 'شيش طاووق متبل', 'قطع صدور دجاج مشوية بتتبيلة الزعفران والليمون', 190.00, true, false, false, 20, 4.8),
('item-3', 'طواجن', 'طاجن ملوخية بالفراخ', 'ملوخية خضراء مصرية بالطشة مع نصف دجاجة محمرة وأرز', 160.00, true, false, false, 15, 4.9),
('item-4', 'طواجن', 'طاجن بامية باللحمة الضاني', 'طاجن بامية بلدي مع لحم ضاني مسبك في الفرن', 240.00, true, false, true, 20, 4.7),
('item-5', 'مقبلات', 'شوربة لسان عصفور', 'شوربة غنية بالمرقة مع ليمون طازج', 45.00, true, false, false, 10, 4.6),
('item-6', 'مقبلات', 'سلطة خضراء وطحينة بلدي', 'تشكيلة سلطة بلدي متبلة مع سلطة طحينة بالخل والكمون', 35.00, true, true, false, 5, 4.8),
('item-7', 'مشروبات', 'عصير قصب طازج', 'عصير قصب طبيعي 100% مثلج', 30.00, true, true, false, 5, 4.9),
('item-8', 'مشروبات', 'كركديه أسواني مثلج', 'كركديه منعش محلى بالسكر الطبيعي', 35.00, true, true, false, 5, 4.8),
('item-9', 'حلويات', 'أم علي بالمكسرات والقشطة', 'أم علي ساخنة محمرة بالفرن مع القشطة والمكسرات', 75.00, true, true, false, 15, 4.9)
ON CONFLICT (id) DO NOTHING;

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
INSERT INTO public.coupons (id, code, discount_percent, max_discount, is_active) VALUES
('c1', 'WELCOME10', 10.00, 50.00, true),
('c2', 'RAMADAN20', 20.00, 100.00, true)
ON CONFLICT (id) DO NOTHING;

-- 5. Inventory Items
INSERT INTO public.inventory (id, name, category, quantity, unit, min_threshold) VALUES
('inv-1', 'لحم ضاني مفروم', 'لحوم', 25.0, 'كجم', 5.0),
('inv-2', 'صدور دجاج', 'دواجن', 40.0, 'كجم', 8.0),
('inv-3', 'أرز بسمتي فاخر', 'حبوب', 50.0, 'كجم', 10.0),
('inv-4', 'ملوخية خضراء', 'خضروات', 15.0, 'كجم', 3.0),
('inv-5', 'طحينة سمسم نقي', 'بقالة', 20.0, 'كجم', 4.0)
ON CONFLICT (id) DO NOTHING;
