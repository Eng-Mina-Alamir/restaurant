-- Migration: 20260904100000_restaurant_actual_tables_count.sql
-- Function to safely return the actual count of physical tables in the restaurant.
-- Read-only, security definer, callable by authenticated staff and anon.

CREATE OR REPLACE FUNCTION public.restaurant_actual_tables_count(p_restaurant_id uuid DEFAULT NULL)
RETURNS integer
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT count(*)::integer FROM public.tables;
$$;

GRANT EXECUTE ON FUNCTION public.restaurant_actual_tables_count(uuid) TO authenticated, anon;
