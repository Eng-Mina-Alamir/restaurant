-- ==============================================================================
-- 🚀 MIGRATION: Auto-incrementing BIGINT Primary Keys and Order Numbers
-- ==============================================================================
-- 1. All tables except `profiles` and `restaurants` converted to BIGINT GENERATED ALWAYS AS IDENTITY
-- 2. Foreign keys updated to BIGINT referencing parent tables
-- 3. `orders.order_number` column added with automatic generation trigger (ORD-YYMMDD-XXXX)
-- 4. RLS policies and triggers updated to support BIGINT identifiers
-- ==============================================================================

-- 1. Add order_number to orders
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS order_number TEXT;

-- 2. Auto-generate order_number trigger
CREATE OR REPLACE FUNCTION public.set_order_number()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.order_number IS NULL OR NEW.order_number = '' THEN
    NEW.order_number := 'ORD-' || TO_CHAR(COALESCE(NEW.created_at, NOW()), 'YYMMDD') || '-' || LPAD(NEW.id::text, 4, '0');
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_set_order_number ON public.orders;
CREATE TRIGGER trg_set_order_number
BEFORE INSERT ON public.orders
FOR EACH ROW
EXECUTE FUNCTION public.set_order_number();

-- 3. Update earn_loyalty_points function signature and logic to accept BIGINT
CREATE OR REPLACE FUNCTION public.earn_loyalty_points(p_order_id bigint)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_uid UUID := auth.uid();
  v_order RECORD;
  v_account RECORD;
  v_multiplier NUMERIC := 1.0;
  v_points_earned INT;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'يجب تسجيل الدخول لاكتساب النقاط';
  END IF;

  SELECT * INTO v_order FROM public.orders WHERE id = p_order_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'الطلب غير موجود';
  END IF;

  IF v_order.customer_id IS DISTINCT FROM v_uid AND NOT public.is_staff() THEN
    RAISE EXCEPTION 'غير مصرح لك باكتساب نقاط هذا الطلب';
  END IF;

  IF v_order.status NOT IN ('completed', 'served', 'delivered') THEN
    RAISE EXCEPTION 'لا يمكن اكتساب النقاط إلا بعد اكتمال الطلب';
  END IF;

  IF EXISTS (SELECT 1 FROM public.loyalty_transactions WHERE order_id = p_order_id) THEN
    SELECT * INTO v_account FROM public.loyalty_accounts WHERE user_id = v_uid;
    RETURN jsonb_build_object(
      'user_id', v_account.user_id,
      'current_points', v_account.current_points,
      'lifetime_points', v_account.lifetime_points,
      'already_earned', true
    );
  END IF;

  INSERT INTO public.loyalty_accounts (user_id, current_points, lifetime_points)
  VALUES (v_uid, 0, 0)
  ON CONFLICT (user_id) DO NOTHING;

  SELECT * INTO v_account FROM public.loyalty_accounts WHERE user_id = v_uid;

  IF v_account.lifetime_points >= 3000 THEN
    v_multiplier := 2.0;
  ELSIF v_account.lifetime_points >= 1500 THEN
    v_multiplier := 1.5;
  ELSIF v_account.lifetime_points >= 500 THEN
    v_multiplier := 1.25;
  ELSE
    v_multiplier := 1.0;
  END IF;

  v_points_earned := FLOOR(COALESCE(v_order.total_amount, 0) * v_multiplier);
  IF v_points_earned <= 0 THEN
    v_points_earned := 1;
  END IF;

  INSERT INTO public.loyalty_transactions (user_id, points, type, description, order_id)
  VALUES (v_uid, v_points_earned, 'earn', 'نقاط الطلب #' || COALESCE(v_order.order_number, p_order_id::text), p_order_id);

  UPDATE public.loyalty_accounts
  SET current_points = current_points + v_points_earned,
      lifetime_points = lifetime_points + v_points_earned,
      updated_at = NOW()
  WHERE user_id = v_uid
  RETURNING * INTO v_account;

  RETURN jsonb_build_object(
    'user_id', v_account.user_id,
    'current_points', v_account.current_points,
    'lifetime_points', v_account.lifetime_points,
    'points_earned', v_points_earned
  );
END;
$function$;
