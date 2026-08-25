-- ============================================================================
-- RLS POLICIES for the 15 tables that had RLS enabled with ZERO policies
-- (advisor lint rls_enabled_no_policy). These were fully inaccessible via the
-- Data API. Pattern: TO authenticated, InitPlan "(SELECT auth.uid())",
-- recursion-safe helpers, USING + WITH CHECK on UPDATE.
-- Also modernizes storage.objects policies (drops deprecated auth.role()).
-- ============================================================================

-- ── cart_items: owner-only ───────────────────────────────────────────────────
DROP POLICY IF EXISTS cart_items_select ON public.cart_items;
CREATE POLICY cart_items_select ON public.cart_items FOR SELECT TO authenticated
    USING (user_id = (SELECT auth.uid()));
DROP POLICY IF EXISTS cart_items_insert ON public.cart_items;
CREATE POLICY cart_items_insert ON public.cart_items FOR INSERT TO authenticated
    WITH CHECK (user_id = (SELECT auth.uid()));
DROP POLICY IF EXISTS cart_items_update ON public.cart_items;
CREATE POLICY cart_items_update ON public.cart_items FOR UPDATE TO authenticated
    USING (user_id = (SELECT auth.uid())) WITH CHECK (user_id = (SELECT auth.uid()));
DROP POLICY IF EXISTS cart_items_delete ON public.cart_items;
CREATE POLICY cart_items_delete ON public.cart_items FOR DELETE TO authenticated
    USING (user_id = (SELECT auth.uid()));

-- ── cart_item_modifiers: ownership inherited from parent cart item ──────────
DROP POLICY IF EXISTS cart_item_modifiers_select ON public.cart_item_modifiers;
CREATE POLICY cart_item_modifiers_select ON public.cart_item_modifiers FOR SELECT TO authenticated
    USING (EXISTS (SELECT 1 FROM public.cart_items ci
                   WHERE ci.id = cart_item_modifiers.cart_item_id
                     AND ci.user_id = (SELECT auth.uid())));
DROP POLICY IF EXISTS cart_item_modifiers_insert ON public.cart_item_modifiers;
CREATE POLICY cart_item_modifiers_insert ON public.cart_item_modifiers FOR INSERT TO authenticated
    WITH CHECK (EXISTS (SELECT 1 FROM public.cart_items ci
                        WHERE ci.id = cart_item_modifiers.cart_item_id
                          AND ci.user_id = (SELECT auth.uid())));
DROP POLICY IF EXISTS cart_item_modifiers_delete ON public.cart_item_modifiers;
CREATE POLICY cart_item_modifiers_delete ON public.cart_item_modifiers FOR DELETE TO authenticated
    USING (EXISTS (SELECT 1 FROM public.cart_items ci
                   WHERE ci.id = cart_item_modifiers.cart_item_id
                     AND ci.user_id = (SELECT auth.uid())));

-- ── order_item_modifiers: ownership inherited from order_items -> orders ─────
DROP POLICY IF EXISTS order_item_modifiers_select ON public.order_item_modifiers;
CREATE POLICY order_item_modifiers_select ON public.order_item_modifiers FOR SELECT TO authenticated
    USING (EXISTS (
        SELECT 1 FROM public.order_items oi
        JOIN public.orders o ON o.id::text = oi.order_id::text
        WHERE oi.id = order_item_modifiers.order_item_id
          AND (o.customer_id = (SELECT auth.uid()) OR (SELECT public.is_staff()))
    ));
DROP POLICY IF EXISTS order_item_modifiers_insert ON public.order_item_modifiers;
CREATE POLICY order_item_modifiers_insert ON public.order_item_modifiers FOR INSERT TO authenticated
    WITH CHECK (EXISTS (
        SELECT 1 FROM public.order_items oi
        JOIN public.orders o ON o.id::text = oi.order_id::text
        WHERE oi.id = order_item_modifiers.order_item_id
          AND (o.customer_id = (SELECT auth.uid()) OR (SELECT public.is_staff()))
    ));
DROP POLICY IF EXISTS order_item_modifiers_update ON public.order_item_modifiers;
CREATE POLICY order_item_modifiers_update ON public.order_item_modifiers FOR UPDATE TO authenticated
    USING ((SELECT public.is_staff())) WITH CHECK ((SELECT public.is_staff()));
DROP POLICY IF EXISTS order_item_modifiers_delete ON public.order_item_modifiers;
CREATE POLICY order_item_modifiers_delete ON public.order_item_modifiers FOR DELETE TO authenticated
    USING ((SELECT public.is_staff()) OR (SELECT public.is_manager_or_admin()));

-- ── payments: customer sees own-order payments; staff manage ────────────────
DROP POLICY IF EXISTS payments_select_policy ON public.payments;
CREATE POLICY payments_select_policy ON public.payments FOR SELECT TO authenticated
    USING (EXISTS (SELECT 1 FROM public.orders o
                   WHERE o.id = payments.order_id
                     AND (o.customer_id = (SELECT auth.uid()) OR (SELECT public.is_staff()))));
DROP POLICY IF EXISTS payments_insert_policy ON public.payments;
CREATE POLICY payments_insert_policy ON public.payments FOR INSERT TO authenticated
    WITH CHECK (EXISTS (SELECT 1 FROM public.orders o
                        WHERE o.id = payments.order_id
                          AND (o.customer_id = (SELECT auth.uid()) OR (SELECT public.is_staff()))));
DROP POLICY IF EXISTS payments_update_policy ON public.payments;
CREATE POLICY payments_update_policy ON public.payments FOR UPDATE TO authenticated
    USING ((SELECT public.is_staff())) WITH CHECK ((SELECT public.is_staff()));
DROP POLICY IF EXISTS payments_delete_policy ON public.payments;
CREATE POLICY payments_delete_policy ON public.payments FOR DELETE TO authenticated
    USING ((SELECT public.is_manager_or_admin()));

-- ── invoices: own-order read; staff write ───────────────────────────────────
DROP POLICY IF EXISTS invoices_select_policy ON public.invoices;
CREATE POLICY invoices_select_policy ON public.invoices FOR SELECT TO authenticated
    USING ((SELECT public.is_staff())
           OR EXISTS (SELECT 1 FROM public.orders o
                      WHERE o.id = invoices.order_id
                        AND o.customer_id = (SELECT auth.uid())));
DROP POLICY IF EXISTS invoices_insert_policy ON public.invoices;
CREATE POLICY invoices_insert_policy ON public.invoices FOR INSERT TO authenticated
    WITH CHECK ((SELECT public.has_role(ARRAY['waiter','kitchen','cashier','manager','admin']::text[])));
DROP POLICY IF EXISTS invoices_update_policy ON public.invoices;
CREATE POLICY invoices_update_policy ON public.invoices FOR UPDATE TO authenticated
    USING ((SELECT public.is_staff())) WITH CHECK ((SELECT public.is_staff()));
DROP POLICY IF EXISTS invoices_delete_policy ON public.invoices;
CREATE POLICY invoices_delete_policy ON public.invoices FOR DELETE TO authenticated
    USING ((SELECT public.is_manager_or_admin()));

-- ── discounts: staff-only feature (not referenced by app config) ────────────
DROP POLICY IF EXISTS discounts_select_policy ON public.discounts;
CREATE POLICY discounts_select_policy ON public.discounts FOR SELECT TO authenticated
    USING ((SELECT public.is_staff()));
DROP POLICY IF EXISTS discounts_insert_policy ON public.discounts;
CREATE POLICY discounts_insert_policy ON public.discounts FOR INSERT TO authenticated
    WITH CHECK ((SELECT public.is_manager_or_admin()));
DROP POLICY IF EXISTS discounts_update_policy ON public.discounts;
CREATE POLICY discounts_update_policy ON public.discounts FOR UPDATE TO authenticated
    USING ((SELECT public.is_manager_or_admin())) WITH CHECK ((SELECT public.is_manager_or_admin()));
DROP POLICY IF EXISTS discounts_delete_policy ON public.discounts;
CREATE POLICY discounts_delete_policy ON public.discounts FOR DELETE TO authenticated
    USING ((SELECT public.is_manager_or_admin()));

-- ── inventory_menu_item_link: staff CRUD ─────────────────────────────────────
DROP POLICY IF EXISTS inv_link_select ON public.inventory_menu_item_link;
CREATE POLICY inv_link_select ON public.inventory_menu_item_link FOR SELECT TO authenticated
    USING ((SELECT public.is_staff()));
DROP POLICY IF EXISTS inv_link_insert ON public.inventory_menu_item_link;
CREATE POLICY inv_link_insert ON public.inventory_menu_item_link FOR INSERT TO authenticated
    WITH CHECK ((SELECT public.is_staff()));
DROP POLICY IF EXISTS inv_link_update ON public.inventory_menu_item_link;
CREATE POLICY inv_link_update ON public.inventory_menu_item_link FOR UPDATE TO authenticated
    USING ((SELECT public.is_staff())) WITH CHECK ((SELECT public.is_staff()));
DROP POLICY IF EXISTS inv_link_delete ON public.inventory_menu_item_link;
CREATE POLICY inv_link_delete ON public.inventory_menu_item_link FOR DELETE TO authenticated
    USING ((SELECT public.is_staff()));

-- ── restaurant_categories: mirror categories pattern ─────────────────────────
DROP POLICY IF EXISTS restaurant_categories_select ON public.restaurant_categories;
CREATE POLICY restaurant_categories_select ON public.restaurant_categories FOR SELECT TO anon, authenticated
    USING (true);
DROP POLICY IF EXISTS restaurant_categories_insert ON public.restaurant_categories;
CREATE POLICY restaurant_categories_insert ON public.restaurant_categories FOR INSERT TO authenticated
    WITH CHECK ((SELECT public.is_manager_or_admin()));
DROP POLICY IF EXISTS restaurant_categories_update ON public.restaurant_categories;
CREATE POLICY restaurant_categories_update ON public.restaurant_categories FOR UPDATE TO authenticated
    USING ((SELECT public.is_manager_or_admin())) WITH CHECK ((SELECT public.is_manager_or_admin()));
DROP POLICY IF EXISTS restaurant_categories_delete ON public.restaurant_categories;
CREATE POLICY restaurant_categories_delete ON public.restaurant_categories FOR DELETE TO authenticated
    USING ((SELECT public.is_manager_or_admin()));

-- ── restaurant_tables: mirror tables pattern (select any signed-in user) ────
DROP POLICY IF EXISTS restaurant_tables_select ON public.restaurant_tables;
CREATE POLICY restaurant_tables_select ON public.restaurant_tables FOR SELECT TO anon, authenticated
    USING (true);
DROP POLICY IF EXISTS restaurant_tables_insert ON public.restaurant_tables;
CREATE POLICY restaurant_tables_insert ON public.restaurant_tables FOR INSERT TO authenticated
    WITH CHECK ((SELECT public.is_manager_or_admin()));
DROP POLICY IF EXISTS restaurant_tables_update ON public.restaurant_tables;
CREATE POLICY restaurant_tables_update ON public.restaurant_tables FOR UPDATE TO authenticated
    USING ((SELECT public.is_staff())) WITH CHECK ((SELECT public.is_staff()));
DROP POLICY IF EXISTS restaurant_tables_delete ON public.restaurant_tables;
CREATE POLICY restaurant_tables_delete ON public.restaurant_tables FOR DELETE TO authenticated
    USING ((SELECT public.is_manager_or_admin()));

-- ── staff_performance: self/management read, admin writes ───────────────────
DROP POLICY IF EXISTS staff_performance_select ON public.staff_performance;
CREATE POLICY staff_performance_select ON public.staff_performance FOR SELECT TO authenticated
    USING (user_id = (SELECT auth.uid()) OR (SELECT public.is_staff()));
DROP POLICY IF EXISTS staff_performance_insert ON public.staff_performance;
CREATE POLICY staff_performance_insert ON public.staff_performance FOR INSERT TO authenticated
    WITH CHECK ((SELECT public.is_manager_or_admin()));
DROP POLICY IF EXISTS staff_performance_update ON public.staff_performance;
CREATE POLICY staff_performance_update ON public.staff_performance FOR UPDATE TO authenticated
    USING ((SELECT public.is_manager_or_admin())) WITH CHECK ((SELECT public.is_manager_or_admin()));
DROP POLICY IF EXISTS staff_performance_delete ON public.staff_performance;
CREATE POLICY staff_performance_delete ON public.staff_performance FOR DELETE TO authenticated
    USING ((SELECT public.is_manager_or_admin()));

-- ── sales analytics family: staff read, admin writes ────────────────────────
DROP POLICY IF EXISTS sales_metrics_select ON public.sales_metrics;
CREATE POLICY sales_metrics_select ON public.sales_metrics FOR SELECT TO authenticated
    USING ((SELECT public.is_staff()));
DROP POLICY IF EXISTS sales_metrics_insert ON public.sales_metrics;
CREATE POLICY sales_metrics_insert ON public.sales_metrics FOR INSERT TO authenticated
    WITH CHECK ((SELECT public.is_manager_or_admin()));
DROP POLICY IF EXISTS sales_metrics_update ON public.sales_metrics;
CREATE POLICY sales_metrics_update ON public.sales_metrics FOR UPDATE TO authenticated
    USING ((SELECT public.is_manager_or_admin())) WITH CHECK ((SELECT public.is_manager_or_admin()));
DROP POLICY IF EXISTS sales_metrics_delete ON public.sales_metrics;
CREATE POLICY sales_metrics_delete ON public.sales_metrics FOR DELETE TO authenticated
    USING ((SELECT public.is_manager_or_admin()));

DROP POLICY IF EXISTS sales_items_sold_select ON public.sales_items_sold;
CREATE POLICY sales_items_sold_select ON public.sales_items_sold FOR SELECT TO authenticated
    USING ((SELECT public.is_staff()));
DROP POLICY IF EXISTS sales_items_sold_write ON public.sales_items_sold;
CREATE POLICY sales_items_sold_write ON public.sales_items_sold
    FOR ALL TO authenticated
    USING ((SELECT public.is_manager_or_admin()))
    WITH CHECK ((SELECT public.is_manager_or_admin()));

DROP POLICY IF EXISTS sales_category_revenue_select ON public.sales_category_revenue;
CREATE POLICY sales_category_revenue_select ON public.sales_category_revenue FOR SELECT TO authenticated
    USING ((SELECT public.is_staff()));
DROP POLICY IF EXISTS sales_category_revenue_write ON public.sales_category_revenue;
CREATE POLICY sales_category_revenue_write ON public.sales_category_revenue
    FOR ALL TO authenticated
    USING ((SELECT public.is_manager_or_admin()))
    WITH CHECK ((SELECT public.is_manager_or_admin()));

DROP POLICY IF EXISTS sales_payment_method_revenue_select ON public.sales_payment_method_revenue;
CREATE POLICY sales_payment_method_revenue_select ON public.sales_payment_method_revenue FOR SELECT TO authenticated
    USING ((SELECT public.is_staff()));
DROP POLICY IF EXISTS sales_payment_method_revenue_write ON public.sales_payment_method_revenue;
CREATE POLICY sales_payment_method_revenue_write ON public.sales_payment_method_revenue
    FOR ALL TO authenticated
    USING ((SELECT public.is_manager_or_admin()))
    WITH CHECK ((SELECT public.is_manager_or_admin()));

-- ============================================================================
-- STORAGE: drop deprecated auth.role() usage; owner-scoped avatar upsert needs
-- INSERT+SELECT+UPDATE plus explicit WITH CHECK on UPDATE.
-- ============================================================================
DROP POLICY IF EXISTS delivery_proofs_insert ON storage.objects;
CREATE POLICY delivery_proofs_insert ON storage.objects FOR INSERT TO authenticated
    WITH CHECK (bucket_id = 'delivery-proofs' AND (SELECT public.is_staff()));

DROP POLICY IF EXISTS avatars_owner_update ON storage.objects;
CREATE POLICY avatars_owner_update ON storage.objects FOR UPDATE TO authenticated
    USING (bucket_id = 'user-avatars' AND (storage.foldername(name))[1] = ((SELECT auth.uid())::text))
    WITH CHECK (bucket_id = 'user-avatars' AND (storage.foldername(name))[1] = ((SELECT auth.uid())::text));

DROP POLICY IF EXISTS avatars_owner_insert ON storage.objects;
CREATE POLICY avatars_owner_insert ON storage.objects FOR INSERT TO authenticated
    WITH CHECK (bucket_id = 'user-avatars' AND (storage.foldername(name))[1] = ((SELECT auth.uid())::text));
