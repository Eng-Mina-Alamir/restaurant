-- Let the ordering customer read the dispatch row of their OWN order so the
-- tracking page can show the assigned driver (name/rating/phone) live.
-- Permissive policies are OR-ed: driver/manager access is untouched.
DROP POLICY IF EXISTS "delivery_assignments_select_customer"
  ON public.delivery_assignments;
CREATE POLICY "delivery_assignments_select_customer"
  ON public.delivery_assignments
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.orders o
      WHERE o.id = public.delivery_assignments.order_id
        AND o.customer_id = (SELECT auth.uid())
    )
  );
