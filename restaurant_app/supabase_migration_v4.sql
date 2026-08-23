-- ==============================================================================
-- 💬 MIGRATION V4 — CUSTOMER ↔ DRIVER CHAT
-- ==============================================================================
-- HOW TO APPLY:
--   1. Open Supabase Dashboard → SQL Editor
--   2. Paste this ENTIRE file and run it
--   3. Safe to re-run: tables/columns/indexes use IF NOT EXISTS and every
--      policy is preceded by DROP POLICY IF EXISTS.
--
-- CONTENTS (mirrors the "SCHEMA V4" section of supabase_schema.sql):
--   • chat_messages table (order-scoped conversation, ON DELETE CASCADE)
--   • RLS: customer of the order / assigned driver / managers+admins only;
--     INSERT additionally binds sender_id = auth.uid()
--
-- ⚠️ APPLY AFTER supabase_migration_v3.sql (depends on orders + profiles +
--    delivery_assignments objects).
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id TEXT NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.profiles(id),
    body TEXT NOT NULL CHECK (char_length(body) BETWEEN 1 AND 1000),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_chat_messages_order_id ON public.chat_messages(order_id);

ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS chat_messages_select ON public.chat_messages;
CREATE POLICY chat_messages_select ON public.chat_messages
    FOR SELECT TO authenticated
    USING (sender_id = auth.uid()
           OR public.is_manager_or_admin()
           OR EXISTS (
               SELECT 1 FROM public.orders o
               WHERE o.id = chat_messages.order_id
                 AND o.customer_id = auth.uid()
           )
           OR EXISTS (
               SELECT 1 FROM public.delivery_assignments da
               WHERE da.order_id = chat_messages.order_id
                 AND da.driver_id = auth.uid()
           ));
DROP POLICY IF EXISTS chat_messages_insert ON public.chat_messages;
CREATE POLICY chat_messages_insert ON public.chat_messages
    FOR INSERT TO authenticated
    WITH CHECK (sender_id = auth.uid()
                AND (
                    public.is_manager_or_admin()
                    OR EXISTS (
                        SELECT 1 FROM public.orders o
                        WHERE o.id = chat_messages.order_id
                          AND o.customer_id = auth.uid()
                    )
                    OR EXISTS (
                        SELECT 1 FROM public.delivery_assignments da
                        WHERE da.order_id = chat_messages.order_id
                          AND da.driver_id = auth.uid()
                    )
                ));
