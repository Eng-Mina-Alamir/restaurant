-- Per-order random delivery verification codes (OTP + QR).
--
-- Each delivery order gets its OWN random 6-digit code, minted on first view
-- and rotated after expiry/consumption. Replaces the legacy deterministic
-- "last-4-of-order-id" PIN (predictable) and the universal '1234' bypass.
-- NOTE: order_id is TEXT with NO FK: the app keys orders by `order_number`
-- (TEXT like 'ORD-0042') while `orders.id` is BIGINT — a FK would reject
-- every app-generated id. Rows are best-effort cleaned when orders vanish.
CREATE TABLE IF NOT EXISTS public.delivery_verification_codes (
  order_id TEXT PRIMARY KEY,
  code TEXT NOT NULL CHECK (code ~ '^[0-9]{4,8}$'),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '12 hours'),
  used_at TIMESTAMPTZ,
  attempts INT NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_delivery_verification_codes_expires
  ON public.delivery_verification_codes (expires_at);

ALTER TABLE public.delivery_verification_codes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "delivery_codes_select_authenticated"
  ON public.delivery_verification_codes;
CREATE POLICY "delivery_codes_select_authenticated"
  ON public.delivery_verification_codes
  FOR SELECT TO authenticated
  USING (true);

DROP POLICY IF EXISTS "delivery_codes_insert_authenticated"
  ON public.delivery_verification_codes;
CREATE POLICY "delivery_codes_insert_authenticated"
  ON public.delivery_verification_codes
  FOR INSERT TO authenticated
  WITH CHECK (true);

DROP POLICY IF EXISTS "delivery_codes_update_authenticated"
  ON public.delivery_verification_codes;
CREATE POLICY "delivery_codes_update_authenticated"
  ON public.delivery_verification_codes
  FOR UPDATE TO authenticated
  USING (true)
  WITH CHECK (true);
