-- ============================================================================
-- E2E SMOKE-TEST PREP FIXES (found while integration-testing app flows)
--
-- BUG 1: order_items.id (varchar PK) had NO default while the app's
--        SupabaseOrderRepository.upsert(itemsPayload) omits 'id' entirely.
--        Every line-item insert failed with NOT NULL violation and was
--        swallowed by a catch -> orders saved but items silently lost.
-- FIX:   generate text UUIDs server-side.
--
-- GAP 2: Realtime postgres_changes only delivers events for tables listed in
--        the supabase_realtime publication. chat_messages (chat watch),
--        delivery_assignments (dispatch/assignment broadcasts) and
--        order_status_log (audit trail UIs) were MISSING -> realtime was dead
--        for exactly the features that need it.
-- ============================================================================

ALTER TABLE public.order_items
    ALTER COLUMN id SET DEFAULT gen_random_uuid()::text;

ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.delivery_assignments;
ALTER PUBLICATION supabase_realtime ADD TABLE public.order_status_log;
