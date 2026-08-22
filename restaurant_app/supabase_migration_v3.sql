-- ==============================================================================
-- 🚀 MIGRATION V3 — DELIVERY DISPATCH & ORDER STATUS AUDIT
-- ==============================================================================
-- HOW TO APPLY:
--   1. Open Supabase Dashboard → SQL Editor
--   2. Paste this ENTIRE file and run it
--   3. Safe to re-run — every statement is idempotent (IF NOT EXISTS everywhere)
--
-- CONTENTS (mirrors the "SCHEMA V3" section of supabase_schema.sql, commit 567b62f):
--   • orders.assigned_kitchen_id / orders.driver_id dispatch columns
--   • profiles.is_available / rating / vehicle_info driver fields
--   • delivery_assignments table (+ indexes, RLS policies)
--   • order_status_log audit table (+ index, RLS policies)
--
-- ⚠️ REQUIRED BEFORE DEPLOYING APP v3: without these objects every order insert
--    touching assigned_kitchen_id/driver_id fails with PGRST204.
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
    WITH CHECK (public.is_staff());
