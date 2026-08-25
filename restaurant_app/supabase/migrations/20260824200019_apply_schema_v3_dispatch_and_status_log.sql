-- ============================================================================
-- SCHEMA V3 (previously never applied to remote): dispatch columns, driver
-- profile fields, order_status_log audit table. delivery_assignments already
-- exists remotely -> align types/constraints and add policies only.
-- All predicates use InitPlan form "(SELECT auth.uid())" for per-statement
-- evaluation, and helper calls are wrapped as "(SELECT fn())" so Postgres
-- evaluates them once per query, not once per row.
-- ============================================================================

ALTER TABLE public.orders
    ADD COLUMN IF NOT EXISTS assigned_kitchen_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS driver_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_orders_assigned_kitchen_id ON public.orders(assigned_kitchen_id);
CREATE INDEX IF NOT EXISTS idx_orders_driver_id ON public.orders(driver_id);

ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS is_available BOOLEAN NOT NULL DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS rating NUMERIC(2,1) NOT NULL DEFAULT 5.0,
    ADD COLUMN IF NOT EXISTS vehicle_info TEXT;

-- ---------------------------------------------------------------------------
-- order_status_log: audit trail of status transitions
-- ---------------------------------------------------------------------------
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
CREATE INDEX IF NOT EXISTS idx_order_status_log_order_created ON public.order_status_log(order_id, created_at DESC);

ALTER TABLE public.order_status_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS order_status_log_select ON public.order_status_log;
CREATE POLICY order_status_log_select ON public.order_status_log
    FOR SELECT TO authenticated
    USING (
        (SELECT public.is_manager_or_admin())
        OR EXISTS (
            SELECT 1 FROM public.orders o
            WHERE o.id = order_status_log.order_id
              AND o.customer_id = (SELECT auth.uid())
        )
        OR EXISTS (
            SELECT 1 FROM public.delivery_assignments da
            WHERE da.order_id = order_status_log.order_id
              AND da.driver_id = (SELECT auth.uid())
        )
    );

DROP POLICY IF EXISTS order_status_log_insert ON public.order_status_log;
CREATE POLICY order_status_log_insert ON public.order_status_log
    FOR INSERT TO authenticated
    WITH CHECK (
        (SELECT public.has_role(ARRAY['waiter','kitchen','cashier','manager','admin']::text[]))
        AND changed_by = (SELECT auth.uid())
    );

-- ---------------------------------------------------------------------------
-- delivery_assignments: table exists; normalize timestamps to timestamptz,
-- add the spec CHECK constraints if missing, then apply policies.
-- Table currently has 0 rows, so type changes are safe.
-- ---------------------------------------------------------------------------

DO $$
BEGIN
    ALTER TABLE public.delivery_assignments
        ALTER COLUMN pickup_time TYPE timestamptz USING pickup_time AT TIME ZONE 'UTC';
EXCEPTION WHEN undefined_column THEN NULL;
END $$;

DO $$
BEGIN
    ALTER TABLE public.delivery_assignments
        ALTER COLUMN delivered_time TYPE timestamptz USING delivered_time AT TIME ZONE 'UTC';
EXCEPTION WHEN undefined_column THEN NULL;
END $$;

DO $$
BEGIN
    ALTER TABLE public.delivery_assignments
        ALTER COLUMN created_at TYPE timestamptz USING created_at AT TIME ZONE 'UTC',
        ALTER COLUMN updated_at TYPE timestamptz USING updated_at AT TIME ZONE 'UTC';
EXCEPTION WHEN undefined_column THEN NULL;
END $$;

DO $$
BEGIN
    ALTER TABLE public.delivery_assignments
        ALTER COLUMN assigned_at TYPE timestamptz USING assigned_at AT TIME ZONE 'UTC';
EXCEPTION WHEN undefined_column THEN NULL;
END $$;

DO $$
BEGIN
    ALTER TABLE public.delivery_assignments ADD CONSTRAINT delivery_assignments_status_check
        CHECK (delivery_status IN ('pending','accepted','pickedUp','inTransit','delivered','failed'));
EXCEPTION WHEN duplicate_object THEN NULL; WHEN undefined_table THEN NULL;
END $$;

DO $$
BEGIN
    ALTER TABLE public.delivery_assignments ADD CONSTRAINT delivery_assignments_method_check
        CHECK (assignment_method IN ('auto','manual'));
EXCEPTION WHEN duplicate_object THEN NULL; WHEN undefined_column THEN NULL;
END $$;

ALTER TABLE public.delivery_assignments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS delivery_assignments_select_policy ON public.delivery_assignments;
DROP POLICY IF EXISTS delivery_assignments_update_driver ON public.delivery_assignments;
DROP POLICY IF EXISTS delivery_assignments_insert ON public.delivery_assignments;
DROP POLICY IF EXISTS delivery_assignments_manage ON public.delivery_assignments;

CREATE POLICY delivery_assignments_select_policy ON public.delivery_assignments
    FOR SELECT TO authenticated
    USING (driver_id = (SELECT auth.uid()) OR (SELECT public.is_manager_or_admin()));

CREATE POLICY delivery_assignments_update_driver ON public.delivery_assignments
    FOR UPDATE TO authenticated
    USING (driver_id = (SELECT auth.uid()))
    WITH CHECK (driver_id = (SELECT auth.uid()));

CREATE POLICY delivery_assignments_insert ON public.delivery_assignments
    FOR INSERT TO authenticated
    WITH CHECK (
        driver_id = (SELECT auth.uid())
        OR (SELECT public.has_role(ARRAY['waiter','kitchen','cashier','manager','admin']::text[]))
    );

CREATE POLICY delivery_assignments_manage ON public.delivery_assignments
    FOR ALL TO authenticated
    USING ((SELECT public.is_manager_or_admin()))
    WITH CHECK ((SELECT public.is_manager_or_admin()));
