-- ============================================================================
-- MISSING RELATIONS & INDEXES
-- 1) FKs that were dangling references before (validated after cleaning any
--    orphans; orders/reservations are empty, tables rows pre-cleaned).
-- 2) Backing indexes for every new FK column.
-- 3) loyalty_transactions: replace blanket UNIQUE(order_id) -- which capped
--    history at ONE transaction per order and blocks earn+bonus+redeem flows
--    on the same order -- with a PARTIAL unique that only dedupes 'earn'.
-- 4) Composite index for chat pagination.
-- ============================================================================

-- ── clean dangling values so FK validation passes ───────────────────────────
UPDATE public.tables t
   SET current_order_id = NULL
 WHERE current_order_id IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM public.orders o WHERE o.id::text = t.current_order_id);

UPDATE public.restaurant_tables t
   SET current_order_id = NULL
 WHERE current_order_id IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM public.orders o WHERE o.id::text = t.current_order_id);

-- ── add the missing foreign keys (idempotent via DO guards) ─────────────────
DO $$
BEGIN
    ALTER TABLE public.orders ADD CONSTRAINT orders_discount_id_fkey
        FOREIGN KEY (discount_id) REFERENCES public.discounts(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL; WHEN duplicate_table THEN NULL;
END $$;

DO $$
BEGIN
    ALTER TABLE public.reservations ADD CONSTRAINT reservations_customer_id_fkey
        FOREIGN KEY (customer_id) REFERENCES public.profiles(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL; WHEN duplicate_table THEN NULL;
END $$;

DO $$
BEGIN
    ALTER TABLE public.tables ADD CONSTRAINT tables_current_order_id_fkey
        FOREIGN KEY (current_order_id) REFERENCES public.orders(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL; WHEN duplicate_table THEN NULL;
END $$;

DO $$
BEGIN
    ALTER TABLE public.restaurant_tables ADD CONSTRAINT restaurant_tables_current_order_id_fkey
        FOREIGN KEY (current_order_id) REFERENCES public.orders(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL; WHEN duplicate_table THEN NULL;
END $$;

-- ── backing indexes for new FK columns ──────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_orders_discount_id ON public.orders(discount_id);
CREATE INDEX IF NOT EXISTS idx_reservations_customer_id ON public.reservations(customer_id);
CREATE INDEX IF NOT EXISTS idx_tables_current_order ON public.tables(current_order_id);
CREATE INDEX IF NOT EXISTS idx_restaurant_tables_current_order ON public.restaurant_tables(current_order_id);

-- ── loyalty_transactions: swap UNIQUE(order_id) for a scoped partial unique ─
ALTER TABLE public.loyalty_transactions DROP CONSTRAINT IF EXISTS loyalty_transactions_order_id_key;

DROP INDEX IF EXISTS idx_loyalty_transactions_order_earn_uniq;
CREATE UNIQUE INDEX loyalty_transactions_order_earn_uniq
    ON public.loyalty_transactions(order_id)
    WHERE type = 'earn' AND order_id IS NOT NULL;

-- plain lookup index for FK joins / order history queries
DROP INDEX IF EXISTS idx_loyalty_transactions_order_id;
CREATE INDEX IF NOT EXISTS idx_loyalty_transactions_order_id ON public.loyalty_transactions(order_id);

-- ── chat pagination composite (already created in v4 apply; re-assert) ──────
CREATE INDEX IF NOT EXISTS idx_chat_messages_order_created ON public.chat_messages(order_id, created_at DESC);
