-- ============================================================================
-- ORDER ARCHIVAL: Soft-archive old completed/cancelled orders
-- ----------------------------------------------------------------------------
-- PROBLEM: The orders table grows indefinitely. The app now limits queries
-- to 90 days, but old rows still consume storage on the free plan.
--
-- FIX: Add an `is_archived` flag. A pg_cron job (runs daily at 3 AM Cairo
-- time) marks completed/cancelled orders older than 90 days as archived.
-- Archived orders are excluded from default queries via a partial index.
-- Data is preserved for reporting; use `WHERE is_archived = false` or
-- omit the filter for full history.
-- ============================================================================

-- 1. Add the archive flag (default false so existing rows are unaffected)
ALTER TABLE public.orders
    ADD COLUMN IF NOT EXISTS is_archived BOOLEAN NOT NULL DEFAULT false;

-- 2. Partial index: queries filtering non-archived orders skip archived rows
--    entirely (index-only scan on the active subset).
CREATE INDEX IF NOT EXISTS idx_orders_active
    ON public.orders (created_at DESC)
    WHERE is_archived = false;

-- 3. Archive function
CREATE OR REPLACE FUNCTION public.archive_old_orders()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    UPDATE public.orders
    SET is_archived = true
    WHERE is_archived = false
      AND status IN ('completed', 'cancelled', 'delivered')
      AND created_at < NOW() - INTERVAL '90 days';

    RAISE LOG 'archive_old_orders: archived % rows', FOUND;
END;
$$;

-- Restrict execution to service_role only
REVOKE EXECUTE ON FUNCTION public.archive_old_orders() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.archive_old_orders() TO service_role;

-- 4. Schedule daily archival at 3 AM Cairo time (UTC+2 → 01:00 UTC)
--    pg_cron is available on Supabase free plan.
SELECT cron.schedule(
    'archive-old-orders',
    '0 1 * * *',
    $$SELECT public.archive_old_orders()$$
);
