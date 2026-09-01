-- ==============================================================================
-- 🚀 MIGRATION: Fix orders and delivery schema, add missing columns and indexes
-- ==============================================================================

-- 1. Add items_json to orders table if not exists
ALTER TABLE public.orders 
ADD COLUMN IF NOT EXISTS items_json JSONB DEFAULT '[]'::jsonb;

-- 2. Add assigned_at and assignment_method to delivery_assignments
ALTER TABLE public.delivery_assignments 
ADD COLUMN IF NOT EXISTS assigned_at TIMESTAMPTZ DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS assignment_method VARCHAR DEFAULT 'auto';

-- 3. Add covering indexes for unindexed foreign keys
CREATE INDEX IF NOT EXISTS idx_driver_locations_order_id 
ON public.driver_locations(order_id);

CREATE INDEX IF NOT EXISTS idx_order_status_log_changed_by 
ON public.order_status_log(changed_by);

CREATE INDEX IF NOT EXISTS idx_table_service_requests_waiter 
ON public.table_service_requests(handled_by_waiter_id);

-- 4. Ensure default restaurant ID matches the live record
ALTER TABLE public.orders 
ALTER COLUMN restaurant_id SET DEFAULT '1e08b47c-15be-4604-a913-431af7fbd54f'::uuid;
