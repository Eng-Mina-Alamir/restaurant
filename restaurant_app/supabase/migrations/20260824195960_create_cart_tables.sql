-- ============================================================================
-- CREATE CLOUD CART TABLES (cart_items / cart_item_modifiers)
-- ----------------------------------------------------------------------------
-- WHY: the tables were created manually on the live project and only the RLS
-- migration (20260824200222) referenced them — a fresh `supabase db reset`
-- or new project would fail there with undefined_table.
-- SOURCE: mirrors the live schema exactly (columns, NOT NULLs, FKs, the
-- cart_item_modifiers_pair_uniq composite UNIQUE added by
-- 20260824200409_integrity_constraints_cleanup.sql, and all indexes).
-- SAFETY: every statement is idempotent (IF NOT EXISTS / guarded DO blocks)
-- so running this against the already-migrated live DB is a no-op.
-- See DEPLOYMENT.md §3b for the single-source-of-truth workflow.
-- ============================================================================

-- ── cart_items ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.cart_items (
    id            VARCHAR PRIMARY KEY,
    user_id       UUID NOT NULL REFERENCES public.profiles(id),
    menu_item_id  VARCHAR NOT NULL REFERENCES public.menu_items(id),
    quantity      INTEGER NOT NULL DEFAULT 1,
    special_notes TEXT,
    created_at    TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE public.cart_items ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_cart_items_user_id      ON public.cart_items (user_id);
CREATE INDEX IF NOT EXISTS idx_cart_items_menu_item_id ON public.cart_items (menu_item_id);

-- ── cart_item_modifiers ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.cart_item_modifiers (
    id                VARCHAR PRIMARY KEY,
    cart_item_id      VARCHAR NOT NULL REFERENCES public.cart_items(id),
    modifier_option_id VARCHAR NOT NULL REFERENCES public.menu_modifier_options(id)
);

ALTER TABLE public.cart_item_modifiers ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    ALTER TABLE public.cart_item_modifiers ADD CONSTRAINT cart_item_modifiers_pair_uniq
        UNIQUE (cart_item_id, modifier_option_id);
EXCEPTION WHEN duplicate_table THEN NULL; WHEN undefined_table THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS idx_cart_item_modifiers_cart_item_id ON public.cart_item_modifiers (cart_item_id);
CREATE INDEX IF NOT EXISTS idx_cart_item_modifiers_option_id    ON public.cart_item_modifiers (modifier_option_id);
