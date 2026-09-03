-- ==============================================================================
-- 🚀 MIGRATION: Clean Remaining Duplicate Policies & Constraints
-- ==============================================================================

-- ratings
DROP POLICY IF EXISTS "ratings_insert_policy" ON public.ratings;
DROP POLICY IF EXISTS "ratings_select" ON public.ratings;

-- reservations
DROP POLICY IF EXISTS "reservations_manage" ON public.reservations;
DROP POLICY IF EXISTS "reservations_insert" ON public.reservations;
DROP POLICY IF EXISTS "reservations_select" ON public.reservations;

-- sales metrics duplicate select policies
DROP POLICY IF EXISTS "sales_category_revenue_write" ON public.sales_category_revenue;
DROP POLICY IF EXISTS "sales_items_sold_write" ON public.sales_items_sold;
DROP POLICY IF EXISTS "sales_payment_method_revenue_write" ON public.sales_payment_method_revenue;

-- Recreate write policies as FOR INSERT / UPDATE / DELETE instead of ALL
CREATE POLICY "sales_category_revenue_modify" ON public.sales_category_revenue 
  FOR INSERT TO authenticated WITH CHECK ((SELECT is_manager_or_admin()));

CREATE POLICY "sales_items_sold_modify" ON public.sales_items_sold 
  FOR INSERT TO authenticated WITH CHECK ((SELECT is_manager_or_admin()));

CREATE POLICY "sales_payment_method_revenue_modify" ON public.sales_payment_method_revenue 
  FOR INSERT TO authenticated WITH CHECK ((SELECT is_manager_or_admin()));

-- Drop duplicate unique constraint
ALTER TABLE public.inventory_menu_item_link DROP CONSTRAINT IF EXISTS inv_link_pair_uniq;
