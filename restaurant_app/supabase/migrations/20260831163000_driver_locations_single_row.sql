-- ============================================================================
-- DRIVER LOCATIONS: Single row per driver (upsert on driver_id)
-- ----------------------------------------------------------------------------
-- PROBLEM: driver_locations uses BIGSERIAL PK so every location update
-- inserts a new row, causing unbounded growth. At ~10 updates/min per
-- driver × 8 hours × N drivers, the free plan's 500MB fills fast.
--
-- FIX: Replace BIGSERIAL PK with driver_id as PK. The app already uses
-- .upsert(), so the conflict resolution now works correctly and each
-- driver maintains exactly ONE row — the latest known location.
--
-- MIGRATION STRATEGY: Recreate the table to change the PK. Preserving
-- only the most recent row per driver from the old data.
-- ============================================================================

-- 1. Create the new table structure
CREATE TABLE IF NOT EXISTS public.driver_locations_v2 (
    driver_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    order_id TEXT REFERENCES public.orders(id) ON DELETE SET NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Migrate the latest row per driver from old table
INSERT INTO public.driver_locations_v2 (driver_id, order_id, latitude, longitude, updated_at)
SELECT DISTINCT ON (driver_id)
    driver_id, order_id, latitude, longitude, updated_at
FROM public.driver_locations
ORDER BY driver_id, updated_at DESC
ON CONFLICT (driver_id) DO NOTHING;

-- 3. Drop old table and rename
DROP TABLE IF EXISTS public.driver_locations;
ALTER TABLE public.driver_locations_v2 RENAME TO driver_locations;

-- 4. Re-add to realtime publication (was on old table)
ALTER PUBLICATION supabase_realtime ADD TABLE public.driver_locations;

-- 5. Add index for updated_at (useful for cleanup queries and monitoring)
CREATE INDEX IF NOT EXISTS idx_driver_locations_updated_at
    ON public.driver_locations (updated_at DESC);

-- 6. Re-apply RLS (the old table's policies were dropped with it)
ALTER TABLE public.driver_locations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Drivers can upsert own location"
    ON public.driver_locations
    FOR ALL
    USING (driver_id = (SELECT auth.uid()))
    WITH CHECK (driver_id = (SELECT auth.uid()));

CREATE POLICY "Staff can view all driver locations"
    ON public.driver_locations
    FOR SELECT
    USING (public.is_staff());
