-- ============================================================================
-- SCHEMA V4 (previously never applied): order-scoped customer<->driver chat.
-- Policies use InitPlan form "(SELECT auth.uid())" and recursion-safe helpers.
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id TEXT NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.profiles(id),
    body TEXT NOT NULL CHECK (char_length(body) BETWEEN 1 AND 1000),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_chat_messages_order_id ON public.chat_messages(order_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_order_created ON public.chat_messages(order_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_chat_messages_sender ON public.chat_messages(sender_id);

ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS chat_messages_select ON public.chat_messages;
CREATE POLICY chat_messages_select ON public.chat_messages
    FOR SELECT TO authenticated
    USING (
        sender_id = (SELECT auth.uid())
        OR (SELECT public.is_manager_or_admin())
        OR EXISTS (
            SELECT 1 FROM public.orders o
            WHERE o.id = chat_messages.order_id
              AND o.customer_id = (SELECT auth.uid())
        )
        OR EXISTS (
            SELECT 1 FROM public.delivery_assignments da
            WHERE da.order_id = chat_messages.order_id
              AND da.driver_id = (SELECT auth.uid())
        )
    );

DROP POLICY IF EXISTS chat_messages_insert ON public.chat_messages;
CREATE POLICY chat_messages_insert ON public.chat_messages
    FOR INSERT TO authenticated
    WITH CHECK (
        sender_id = (SELECT auth.uid())
        AND (
            (SELECT public.is_manager_or_admin())
            OR EXISTS (
                SELECT 1 FROM public.orders o
                WHERE o.id = chat_messages.order_id
                  AND o.customer_id = (SELECT auth.uid())
            )
            OR EXISTS (
                SELECT 1 FROM public.delivery_assignments da
                WHERE da.order_id = chat_messages.order_id
                  AND da.driver_id = (SELECT auth.uid())
            )
        )
    );
