-- Safe driver identity for the ordering customer.
--
-- profiles RLS hides driver rows from customers (rightly: it contains email),
-- which would null out the `driver:profiles` join on the tracking page.
-- This SECURITY DEFINER function exposes ONLY the safe card columns
-- (name/phone/rating/vehicle) and ONLY for the caller's own orders.
CREATE OR REPLACE FUNCTION public.get_my_order_driver(p_order_id BIGINT)
RETURNS TABLE (
  driver_id UUID,
  name TEXT,
  phone TEXT,
  rating NUMERIC,
  vehicle_info TEXT
)
SECURITY DEFINER
SET search_path = public
LANGUAGE sql
STABLE
AS $$
  SELECT p.id, p.name, p.phone, p.rating, p.vehicle_info
  FROM public.delivery_assignments da
  JOIN public.orders o ON o.id = da.order_id
  JOIN public.profiles p ON p.id = da.driver_id
  WHERE da.order_id = p_order_id
    AND o.customer_id = (SELECT auth.uid())
  LIMIT 1;
$$;

REVOKE ALL ON FUNCTION public.get_my_order_driver(BIGINT) FROM anon;
GRANT EXECUTE ON FUNCTION public.get_my_order_driver(BIGINT) TO authenticated;
