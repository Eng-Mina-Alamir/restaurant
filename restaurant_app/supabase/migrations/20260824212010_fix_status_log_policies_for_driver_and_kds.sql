-- ============================================================================
-- E2E smoke-test findings:
-- 1) INSERT excluded 'driver', but the app's onDelivered hook makes the DRIVER
--    advance the parent order and write the audit entry -> blocked with 42501.
-- 2) SELECT was manager/participants-only, so KDS (kitchen) could not read
--    the revert trail its guarded-revert logic depends on.
-- ============================================================================

DROP POLICY IF EXISTS order_status_log_insert ON public.order_status_log;
CREATE POLICY order_status_log_insert ON public.order_status_log
    FOR INSERT TO authenticated
    WITH CHECK (
        (SELECT public.has_role(ARRAY['waiter','kitchen','cashier','driver','manager','admin']::text[]))
        AND changed_by = (SELECT auth.uid())
    );

DROP POLICY IF EXISTS order_status_log_select ON public.order_status_log;
CREATE POLICY order_status_log_select ON public.order_status_log
    FOR SELECT TO authenticated
    USING (
        (SELECT public.is_staff())
        OR EXISTS (
            SELECT 1 FROM public.orders o
            WHERE o.id = order_status_log.order_id
              AND o.customer_id = (SELECT auth.uid())
        )
    );
