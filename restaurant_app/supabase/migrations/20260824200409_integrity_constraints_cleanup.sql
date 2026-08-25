-- ============================================================================
-- DATA-INTEGRITY CLEANUP (non-breaking; live data verified compatible)
-- 1) Composite UNIQUEs on junction tables (prevents duplicate modifier links).
-- 2) CHECK constraints for enum-like text columns, matching the Dart enums in
--    lib/core/domain/enums.dart exactly (.name serialization).
-- 3) created_at/updated_at: backfill NULLs then enforce NOT NULL + defaults.
-- 4) Repair mojibake column DEFAULTS (data rows untouched).
-- ============================================================================

-- ── 1) junction-table pair uniqueness ────────────────────────────────────────
DO $$
BEGIN
    ALTER TABLE public.order_item_modifiers ADD CONSTRAINT order_item_modifiers_pair_uniq
        UNIQUE (order_item_id, modifier_option_id);
EXCEPTION WHEN duplicate_table THEN NULL; WHEN undefined_table THEN NULL;
END $$;

DO $$
BEGIN
    ALTER TABLE public.cart_item_modifiers ADD CONSTRAINT cart_item_modifiers_pair_uniq
        UNIQUE (cart_item_id, modifier_option_id);
EXCEPTION WHEN duplicate_table THEN NULL; WHEN undefined_table THEN NULL;
END $$;

DO $$
BEGIN
    ALTER TABLE public.inventory_menu_item_link ADD CONSTRAINT inv_link_pair_uniq
        UNIQUE (inventory_id, menu_item_id);
EXCEPTION WHEN duplicate_table THEN NULL; WHEN undefined_table THEN NULL;
END $$;

-- ── 2) enum-like CHECK constraints (values mirror Dart .name outputs) ───────
DO $$
BEGIN
    ALTER TABLE public.orders ADD CONSTRAINT orders_status_check
        CHECK (status IN ('pending','confirmed','preparing','ready','served','completed','cancelled'));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    ALTER TABLE public.orders ADD CONSTRAINT orders_type_check
        CHECK (order_type IN ('dineIn','takeaway','delivery'));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    ALTER TABLE public.orders ADD CONSTRAINT orders_payment_method_check
        CHECK (payment_method IS NULL OR payment_method IN ('cash','card','wallet','online'));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    ALTER TABLE public.tables ADD CONSTRAINT tables_status_check
        CHECK (status IN ('available','occupied','reserved','needsCleaning'));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    ALTER TABLE public.restaurant_tables ADD CONSTRAINT restaurant_tables_status_check
        CHECK (status IN ('available','occupied','reserved','needsCleaning'));
EXCEPTION WHEN duplicate_object THEN NULL; WHEN undefined_table THEN NULL;
END $$;

DO $$
BEGIN
    ALTER TABLE public.profiles ADD CONSTRAINT profiles_role_check
        CHECK (role IN ('customer','waiter','kitchen','cashier','driver','manager','admin'));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    ALTER TABLE public.coupons ADD CONSTRAINT coupons_discount_type_check
        CHECK (discount_type IN ('percentage','fixed'));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    ALTER TABLE public.discounts ADD CONSTRAINT discounts_discount_type_check
        CHECK (discount_type IN ('percentage','fixed'));
EXCEPTION WHEN duplicate_object THEN NULL; WHEN undefined_table THEN NULL;
END $$;

-- ── 3) timestamp hygiene: backfill, default, NOT NULL ───────────────────────
UPDATE public.profiles      SET created_at = now() WHERE created_at IS NULL;
UPDATE public.categories    SET created_at = now() WHERE created_at IS NULL;
UPDATE public.order_items   SET created_at = now() WHERE created_at IS NULL;
UPDATE public.ratings       SET created_at = now() WHERE created_at IS NULL;
UPDATE public.loyalty_accounts SET created_at = now() WHERE created_at IS NULL;
UPDATE public.loyalty_accounts SET updated_at = now() WHERE updated_at IS NULL;
UPDATE public.tables        SET last_updated = now() WHERE last_updated IS NULL;

ALTER TABLE public.profiles           ALTER COLUMN created_at SET DEFAULT now();
ALTER TABLE public.categories         ALTER COLUMN created_at SET DEFAULT now();
ALTER TABLE public.order_items        ALTER COLUMN created_at SET DEFAULT now();
ALTER TABLE public.ratings            ALTER COLUMN created_at SET DEFAULT now();
ALTER TABLE public.loyalty_accounts   ALTER COLUMN created_at SET DEFAULT now();
ALTER TABLE public.loyalty_accounts   ALTER COLUMN updated_at SET DEFAULT now();
ALTER TABLE public.tables             ALTER COLUMN last_updated SET DEFAULT now();

ALTER TABLE public.profiles           ALTER COLUMN created_at SET NOT NULL;
ALTER TABLE public.categories         ALTER COLUMN created_at SET NOT NULL;
ALTER TABLE public.order_items        ALTER COLUMN created_at SET NOT NULL;
ALTER TABLE public.ratings            ALTER COLUMN created_at SET NOT NULL;
ALTER TABLE public.loyalty_accounts   ALTER COLUMN created_at SET NOT NULL;
ALTER TABLE public.loyalty_accounts   ALTER COLUMN updated_at SET NOT NULL;
ALTER TABLE public.tables             ALTER COLUMN last_updated SET NOT NULL;

-- ── 4) repair mojibake defaults (ASCII-safe values; existing rows kept) ────
ALTER TABLE public.tables              ALTER COLUMN location SET DEFAULT 'Main Hall';
ALTER TABLE public.restaurant_tables   ALTER COLUMN location SET DEFAULT 'Main Hall';
ALTER TABLE public.profiles            ALTER COLUMN name     SET DEFAULT 'New User';
