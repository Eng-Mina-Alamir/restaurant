-- ============================================================================
-- MODERNIZE LEGACY POLICIES
-- 1) PERF: every auth.uid()/helper call wrapped in a scalar subquery
--    "(SELECT ...)" so Postgres evaluates ONCE per statement (InitPlan)
--    instead of once per row.
-- 2) DEPRECATED: auth.role() = 'authenticated' replaced with explicit TO clause.
-- 3) SAFETY: UPDATE policies get WITH CHECK mirroring USING (prevents row
--    reassignment / silent 0-row updates).
-- Semantics preserved exactly; only form hardened.
-- ============================================================================

-- ── categories / coupons (public read, admin writes) ────────────────────────
DROP POLICY IF EXISTS categories_select_policy ON public.categories;
CREATE POLICY categories_select_policy ON public.categories FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS categories_admin_insert ON public.categories;
CREATE POLICY categories_admin_insert ON public.categories FOR INSERT TO authenticated WITH CHECK ((SELECT public.is_manager_or_admin()));
DROP POLICY IF EXISTS categories_admin_update ON public.categories;
CREATE POLICY categories_admin_update ON public.categories FOR UPDATE TO authenticated USING ((SELECT public.is_manager_or_admin())) WITH CHECK ((SELECT public.is_manager_or_admin()));
DROP POLICY IF EXISTS categories_admin_delete ON public.categories;
CREATE POLICY categories_admin_delete ON public.categories FOR DELETE TO authenticated USING ((SELECT public.is_manager_or_admin()));

DROP POLICY IF EXISTS coupons_select_policy ON public.coupons;
CREATE POLICY coupons_select_policy ON public.coupons FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS coupons_admin_insert ON public.coupons;
CREATE POLICY coupons_admin_insert ON public.coupons FOR INSERT TO authenticated WITH CHECK ((SELECT public.is_manager_or_admin()));
DROP POLICY IF EXISTS coupons_admin_update ON public.coupons;
CREATE POLICY coupons_admin_update ON public.coupons FOR UPDATE TO authenticated USING ((SELECT public.is_manager_or_admin())) WITH CHECK ((SELECT public.is_manager_or_admin()));
DROP POLICY IF EXISTS coupons_admin_delete ON public.coupons;
CREATE POLICY coupons_admin_delete ON public.coupons FOR DELETE TO authenticated USING ((SELECT public.is_manager_or_admin()));

-- ── menu_items / modifier groups & options ──────────────────────────────────
DROP POLICY IF EXISTS menu_items_select_policy ON public.menu_items;
CREATE POLICY menu_items_select_policy ON public.menu_items FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS menu_items_admin_insert ON public.menu_items;
CREATE POLICY menu_items_admin_insert ON public.menu_items FOR INSERT TO authenticated WITH CHECK ((SELECT public.is_manager_or_admin()));
DROP POLICY IF EXISTS menu_items_admin_update ON public.menu_items;
CREATE POLICY menu_items_admin_update ON public.menu_items FOR UPDATE TO authenticated USING ((SELECT public.is_manager_or_admin())) WITH CHECK ((SELECT public.is_manager_or_admin()));
DROP POLICY IF EXISTS menu_items_admin_delete ON public.menu_items;
CREATE POLICY menu_items_admin_delete ON public.menu_items FOR DELETE TO authenticated USING ((SELECT public.is_manager_or_admin()));

DROP POLICY IF EXISTS modifier_groups_select_policy ON public.menu_modifier_groups;
CREATE POLICY modifier_groups_select_policy ON public.menu_modifier_groups FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS modifier_groups_admin_insert ON public.menu_modifier_groups;
CREATE POLICY modifier_groups_admin_insert ON public.menu_modifier_groups FOR INSERT TO authenticated WITH CHECK ((SELECT public.is_manager_or_admin()));
DROP POLICY IF EXISTS modifier_groups_admin_update ON public.menu_modifier_groups;
CREATE POLICY modifier_groups_admin_update ON public.menu_modifier_groups FOR UPDATE TO authenticated USING ((SELECT public.is_manager_or_admin())) WITH CHECK ((SELECT public.is_manager_or_admin()));
DROP POLICY IF EXISTS modifier_groups_admin_delete ON public.menu_modifier_groups;
CREATE POLICY modifier_groups_admin_delete ON public.menu_modifier_groups FOR DELETE TO authenticated USING ((SELECT public.is_manager_or_admin()));

DROP POLICY IF EXISTS modifier_options_select_policy ON public.menu_modifier_options;
CREATE POLICY modifier_options_select_policy ON public.menu_modifier_options FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS modifier_options_admin_insert ON public.menu_modifier_options;
CREATE POLICY modifier_options_admin_insert ON public.menu_modifier_options FOR INSERT TO authenticated WITH CHECK ((SELECT public.is_manager_or_admin()));
DROP POLICY IF EXISTS modifier_options_admin_update ON public.menu_modifier_options;
CREATE POLICY modifier_options_admin_update ON public.menu_modifier_options FOR UPDATE TO authenticated USING ((SELECT public.is_manager_or_admin())) WITH CHECK ((SELECT public.is_manager_or_admin()));
DROP POLICY IF EXISTS modifier_options_admin_delete ON public.menu_modifier_options;
CREATE POLICY modifier_options_admin_delete ON public.menu_modifier_options FOR DELETE TO authenticated USING ((SELECT public.is_manager_or_admin()));

-- ── restaurants / loyalty_rewards (public read) ─────────────────────────────
DROP POLICY IF EXISTS restaurants_select_policy ON public.restaurants;
CREATE POLICY restaurants_select_policy ON public.restaurants FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS restaurants_admin_insert ON public.restaurants;
CREATE POLICY restaurants_admin_insert ON public.restaurants FOR INSERT TO authenticated WITH CHECK ((SELECT public.is_manager_or_admin()));
DROP POLICY IF EXISTS restaurants_admin_update ON public.restaurants;
CREATE POLICY restaurants_admin_update ON public.restaurants FOR UPDATE TO authenticated USING ((SELECT public.is_manager_or_admin())) WITH CHECK ((SELECT public.is_manager_or_admin()));
DROP POLICY IF EXISTS restaurants_admin_delete ON public.restaurants;
CREATE POLICY restaurants_admin_delete ON public.restaurants FOR DELETE TO authenticated USING ((SELECT public.is_manager_or_admin()));

DROP POLICY IF EXISTS loyalty_rewards_select_policy ON public.loyalty_rewards;
CREATE POLICY loyalty_rewards_select_policy ON public.loyalty_rewards FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS loyalty_rewards_admin_insert ON public.loyalty_rewards;
CREATE POLICY loyalty_rewards_admin_insert ON public.loyalty_rewards FOR INSERT TO authenticated WITH CHECK ((SELECT public.is_manager_or_admin()));
DROP POLICY IF EXISTS loyalty_rewards_admin_update ON public.loyalty_rewards;
CREATE POLICY loyalty_rewards_admin_update ON public.loyalty_rewards FOR UPDATE TO authenticated USING ((SELECT public.is_manager_or_admin())) WITH CHECK ((SELECT public.is_manager_or_admin()));
DROP POLICY IF EXISTS loyalty_rewards_admin_delete ON public.loyalty_rewards;
CREATE POLICY loyalty_rewards_admin_delete ON public.loyalty_rewards FOR DELETE TO authenticated USING ((SELECT public.is_manager_or_admin()));

-- ── ratings (public read; owner/admin write) ────────────────────────────────
DROP POLICY IF EXISTS ratings_select_policy ON public.ratings;
CREATE POLICY ratings_select_policy ON public.ratings FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS ratings_insert_policy ON public.ratings;
CREATE POLICY ratings_insert_policy ON public.ratings FOR INSERT TO authenticated WITH CHECK (user_id = (SELECT auth.uid()));
DROP POLICY IF EXISTS ratings_update_policy ON public.ratings;
CREATE POLICY ratings_update_policy ON public.ratings FOR UPDATE TO authenticated
    USING (user_id = (SELECT auth.uid()) OR (SELECT public.is_manager_or_admin()))
    WITH CHECK (user_id = (SELECT auth.uid()) OR (SELECT public.is_manager_or_admin()));
DROP POLICY IF EXISTS ratings_delete_policy ON public.ratings;
CREATE POLICY ratings_delete_policy ON public.ratings FOR DELETE TO authenticated USING ((SELECT public.is_manager_or_admin()));

-- ── profiles ─────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS profiles_insert_policy ON public.profiles;
CREATE POLICY profiles_insert_policy ON public.profiles FOR INSERT TO authenticated WITH CHECK (id = (SELECT auth.uid()));
DROP POLICY IF EXISTS profiles_select_policy ON public.profiles;
CREATE POLICY profiles_select_policy ON public.profiles FOR SELECT TO authenticated
    USING (id = (SELECT auth.uid()) OR (SELECT public.is_staff()));
DROP POLICY IF EXISTS profiles_update_policy ON public.profiles;
CREATE POLICY profiles_update_policy ON public.profiles FOR UPDATE TO authenticated
    USING (id = (SELECT auth.uid()) OR (SELECT public.is_manager_or_admin()))
    WITH CHECK (id = (SELECT auth.uid()) OR (SELECT public.is_manager_or_admin()));
DROP POLICY IF EXISTS profiles_delete_policy ON public.profiles;
CREATE POLICY profiles_delete_policy ON public.profiles FOR DELETE TO authenticated USING ((SELECT public.is_manager_or_admin()));

-- ── orders ───────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS orders_insert_policy ON public.orders;
CREATE POLICY orders_insert_policy ON public.orders FOR INSERT TO authenticated
    WITH CHECK (customer_id = (SELECT auth.uid()) OR (SELECT public.is_staff()));
DROP POLICY IF EXISTS orders_select_policy ON public.orders;
CREATE POLICY orders_select_policy ON public.orders FOR SELECT TO authenticated
    USING (customer_id = (SELECT auth.uid()) OR (SELECT public.is_staff()));
DROP POLICY IF EXISTS orders_update_policy ON public.orders;
CREATE POLICY orders_update_policy ON public.orders FOR UPDATE TO authenticated
    USING ((SELECT public.is_staff())) WITH CHECK ((SELECT public.is_staff()));
DROP POLICY IF EXISTS orders_delete_policy ON public.orders;
CREATE POLICY orders_delete_policy ON public.orders FOR DELETE TO authenticated USING ((SELECT public.is_manager_or_admin()));

-- ── order_items ──────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS order_items_insert_policy ON public.order_items;
CREATE POLICY order_items_insert_policy ON public.order_items FOR INSERT TO authenticated
    WITH CHECK (EXISTS (SELECT 1 FROM public.orders o
                        WHERE o.id::text = order_items.order_id::text
                          AND (o.customer_id = (SELECT auth.uid()) OR (SELECT public.is_staff()))));
DROP POLICY IF EXISTS order_items_select_policy ON public.order_items;
CREATE POLICY order_items_select_policy ON public.order_items FOR SELECT TO authenticated
    USING (EXISTS (SELECT 1 FROM public.orders o
                   WHERE o.id::text = order_items.order_id::text
                     AND (o.customer_id = (SELECT auth.uid()) OR (SELECT public.is_staff()))));
DROP POLICY IF EXISTS order_items_update_policy ON public.order_items;
CREATE POLICY order_items_update_policy ON public.order_items FOR UPDATE TO authenticated
    USING ((SELECT public.is_staff())) WITH CHECK ((SELECT public.is_staff()));
DROP POLICY IF EXISTS order_items_delete_policy ON public.order_items;
CREATE POLICY order_items_delete_policy ON public.order_items FOR DELETE TO authenticated USING ((SELECT public.is_staff()) OR (SELECT public.is_manager_or_admin()));

-- ── inventory ────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS inventory_select_policy ON public.inventory;
CREATE POLICY inventory_select_policy ON public.inventory FOR SELECT TO authenticated USING ((SELECT public.is_staff()));
DROP POLICY IF EXISTS inventory_admin_insert ON public.inventory;
CREATE POLICY inventory_admin_insert ON public.inventory FOR INSERT TO authenticated WITH CHECK ((SELECT public.is_manager_or_admin()));
DROP POLICY IF EXISTS inventory_admin_update ON public.inventory;
CREATE POLICY inventory_admin_update ON public.inventory FOR UPDATE TO authenticated USING ((SELECT public.is_manager_or_admin())) WITH CHECK ((SELECT public.is_manager_or_admin()));
DROP POLICY IF EXISTS inventory_admin_delete ON public.inventory;
CREATE POLICY inventory_admin_delete ON public.inventory FOR DELETE TO authenticated USING ((SELECT public.is_manager_or_admin()));

-- ── driver_locations ─────────────────────────────────────────────────────────
DROP POLICY IF EXISTS driver_locations_select_policy ON public.driver_locations;
CREATE POLICY driver_locations_select_policy ON public.driver_locations FOR SELECT TO authenticated
    USING (driver_id = (SELECT auth.uid()) OR (SELECT public.is_staff()));
DROP POLICY IF EXISTS driver_locations_insert_policy ON public.driver_locations;
CREATE POLICY driver_locations_insert_policy ON public.driver_locations FOR INSERT TO authenticated
    WITH CHECK (driver_id = (SELECT auth.uid()) OR (SELECT public.is_staff()));
DROP POLICY IF EXISTS driver_locations_update_policy ON public.driver_locations;
CREATE POLICY driver_locations_update_policy ON public.driver_locations FOR UPDATE TO authenticated
    USING (driver_id = (SELECT auth.uid()) OR (SELECT public.is_staff()))
    WITH CHECK (driver_id = (SELECT auth.uid()) OR (SELECT public.is_staff()));
DROP POLICY IF EXISTS driver_locations_delete_policy ON public.driver_locations;
CREATE POLICY driver_locations_delete_policy ON public.driver_locations FOR DELETE TO authenticated USING ((SELECT public.is_manager_or_admin()));

-- ── reservations ─────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS reservations_select_policy ON public.reservations;
CREATE POLICY reservations_select_policy ON public.reservations FOR SELECT TO authenticated
    USING (user_id = (SELECT auth.uid()) OR (SELECT public.is_staff()));
DROP POLICY IF EXISTS reservations_insert_policy ON public.reservations;
CREATE POLICY reservations_insert_policy ON public.reservations FOR INSERT TO authenticated
    WITH CHECK (user_id = (SELECT auth.uid()) OR user_id IS NULL OR (SELECT public.is_staff()));
DROP POLICY IF EXISTS reservations_update_policy ON public.reservations;
CREATE POLICY reservations_update_policy ON public.reservations FOR UPDATE TO authenticated
    USING ((SELECT public.is_staff())) WITH CHECK ((SELECT public.is_staff()));
DROP POLICY IF EXISTS reservations_delete_policy ON public.reservations;
CREATE POLICY reservations_delete_policy ON public.reservations FOR DELETE TO authenticated USING ((SELECT public.is_manager_or_admin()));

-- ── loyalty_accounts / transactions ──────────────────────────────────────────
DROP POLICY IF EXISTS loyalty_accounts_select_policy ON public.loyalty_accounts;
CREATE POLICY loyalty_accounts_select_policy ON public.loyalty_accounts FOR SELECT TO authenticated
    USING (user_id = (SELECT auth.uid()) OR (SELECT public.is_staff()));
DROP POLICY IF EXISTS loyalty_accounts_admin_insert ON public.loyalty_accounts;
CREATE POLICY loyalty_accounts_admin_insert ON public.loyalty_accounts FOR INSERT TO authenticated WITH CHECK ((SELECT public.is_manager_or_admin()));
DROP POLICY IF EXISTS loyalty_accounts_admin_update ON public.loyalty_accounts;
CREATE POLICY loyalty_accounts_admin_update ON public.loyalty_accounts FOR UPDATE TO authenticated USING ((SELECT public.is_manager_or_admin())) WITH CHECK ((SELECT public.is_manager_or_admin()));
DROP POLICY IF EXISTS loyalty_accounts_admin_delete ON public.loyalty_accounts;
CREATE POLICY loyalty_accounts_admin_delete ON public.loyalty_accounts FOR DELETE TO authenticated USING ((SELECT public.is_manager_or_admin()));

DROP POLICY IF EXISTS loyalty_transactions_select_policy ON public.loyalty_transactions;
CREATE POLICY loyalty_transactions_select_policy ON public.loyalty_transactions FOR SELECT TO authenticated
    USING (user_id = (SELECT auth.uid()) OR (SELECT public.is_staff()));
DROP POLICY IF EXISTS loyalty_transactions_admin_insert ON public.loyalty_transactions;
CREATE POLICY loyalty_transactions_admin_insert ON public.loyalty_transactions FOR INSERT TO authenticated WITH CHECK ((SELECT public.is_manager_or_admin()));
DROP POLICY IF EXISTS loyalty_transactions_admin_update ON public.loyalty_transactions;
CREATE POLICY loyalty_transactions_admin_update ON public.loyalty_transactions FOR UPDATE TO authenticated USING ((SELECT public.is_manager_or_admin())) WITH CHECK ((SELECT public.is_manager_or_admin()));
DROP POLICY IF EXISTS loyalty_transactions_admin_delete ON public.loyalty_transactions;
CREATE POLICY loyalty_transactions_admin_delete ON public.loyalty_transactions FOR DELETE TO authenticated USING ((SELECT public.is_manager_or_admin()));

-- ── tables: replaces deprecated auth.role() = 'authenticated' ───────────────
DROP POLICY IF EXISTS tables_select_policy ON public.tables;
CREATE POLICY tables_select_policy ON public.tables FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS tables_insert_policy ON public.tables;
CREATE POLICY tables_insert_policy ON public.tables FOR INSERT TO authenticated WITH CHECK ((SELECT public.is_manager_or_admin()));
DROP POLICY IF EXISTS tables_update_policy ON public.tables;
CREATE POLICY tables_update_policy ON public.tables FOR UPDATE TO authenticated
    USING ((SELECT public.is_staff())) WITH CHECK ((SELECT public.is_staff()));
DROP POLICY IF EXISTS tables_delete_policy ON public.tables;
CREATE POLICY tables_delete_policy ON public.tables FOR DELETE TO authenticated USING ((SELECT public.is_manager_or_admin()));
