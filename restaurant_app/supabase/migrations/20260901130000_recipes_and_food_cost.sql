-- ==============================================================================
-- 🍽️ ENTERPRISE F&B EXPANSION: RECIPES, FOOD COST, WASTE LOGS & BLIND CASH
-- ==============================================================================

-- 1. Recipe & Bill of Materials (BOM) Table
CREATE TABLE IF NOT EXISTS public.menu_item_recipes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    restaurant_id UUID NOT NULL DEFAULT '1e08b47c-15be-4604-a913-431af7fbd54f'::uuid REFERENCES public.restaurants(id) ON DELETE CASCADE,
    menu_item_id TEXT NOT NULL REFERENCES public.menu_items(id) ON DELETE CASCADE,
    inventory_item_id TEXT NOT NULL REFERENCES public.inventory(id) ON DELETE CASCADE,
    quantity NUMERIC(10, 3) NOT NULL CHECK (quantity > 0),
    unit VARCHAR NOT NULL DEFAULT 'كغ',
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (menu_item_id, inventory_item_id)
);

-- 2. Inventory Waste & Spoilage Logs
CREATE TABLE IF NOT EXISTS public.inventory_waste_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    restaurant_id UUID NOT NULL DEFAULT '1e08b47c-15be-4604-a913-431af7fbd54f'::uuid REFERENCES public.restaurants(id) ON DELETE CASCADE,
    inventory_item_id TEXT NOT NULL REFERENCES public.inventory(id) ON DELETE CASCADE,
    quantity NUMERIC(10, 3) NOT NULL CHECK (quantity > 0),
    unit VARCHAR NOT NULL DEFAULT 'كغ',
    unit_cost NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    total_cost NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    reason TEXT NOT NULL CHECK (reason IN ('expired', 'preparationError', 'customerReturn', 'spoilage', 'damagedDelivery', 'other')),
    logged_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    logged_by_name VARCHAR NOT NULL DEFAULT 'مدير الفرع',
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Indexes for fast lookup
CREATE INDEX IF NOT EXISTS idx_recipes_menu_item ON public.menu_item_recipes(menu_item_id);
CREATE INDEX IF NOT EXISTS idx_recipes_inventory_item ON public.menu_item_recipes(inventory_item_id);
CREATE INDEX IF NOT EXISTS idx_waste_logs_restaurant ON public.inventory_waste_logs(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_waste_logs_inventory ON public.inventory_waste_logs(inventory_item_id);
CREATE INDEX IF NOT EXISTS idx_waste_logs_created ON public.inventory_waste_logs(created_at DESC);

-- 4. Enable RLS on new tables
ALTER TABLE public.menu_item_recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_waste_logs ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies
CREATE POLICY "Staff can view recipes"
    ON public.menu_item_recipes FOR SELECT
    USING (public.is_staff());

CREATE POLICY "Managers and Admin can manage recipes"
    ON public.menu_item_recipes FOR ALL
    USING (public.is_manager_or_admin())
    WITH CHECK (public.is_manager_or_admin());

CREATE POLICY "Staff can view waste logs"
    ON public.inventory_waste_logs FOR SELECT
    USING (public.is_staff());

CREATE POLICY "Staff can insert waste logs"
    ON public.inventory_waste_logs FOR INSERT
    WITH CHECK (public.is_staff());

CREATE POLICY "Managers can manage waste logs"
    ON public.inventory_waste_logs FOR ALL
    USING (public.is_manager_or_admin())
    WITH CHECK (public.is_manager_or_admin());
