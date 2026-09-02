/// Configuration constants for the Supabase backend.
abstract final class SupabaseConfig {
  /// Supabase project URL.
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://iovxfvkaswdediephqep.supabase.co',
  );

  /// Supabase anon / publishable public key.
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_WBFVGk_OwNur8_U0KE3-Fw_XbbNTcii',
  );

  // ── Database Table Names ──────────────────────────────────────────────────
  static const String profilesTable = 'profiles';
  static const String categoriesTable = 'categories';
  static const String menuItemsTable = 'menu_items';
  static const String modifierGroupsTable = 'menu_modifier_groups';
  static const String modifierOptionsTable = 'menu_modifier_options';
  static const String tablesTable = 'tables';
  static const String ordersTable = 'orders';
  static const String orderItemsTable = 'order_items';
  static const String reservationsTable = 'reservations';
  static const String couponsTable = 'coupons';
  static const String ratingsTable = 'ratings';
  static const String inventoryTable = 'inventory';
  static const String driverLocationsTable = 'driver_locations';
  static const String loyaltyAccountsTable = 'loyalty_accounts';
  static const String loyaltyTransactionsTable = 'loyalty_transactions';
  static const String loyaltyRewardsTable = 'loyalty_rewards';
  static const String deliveryAssignmentsTable = 'delivery_assignments';
  static const String orderStatusLogTable = 'order_status_log';
  static const String chatMessagesTable = 'chat_messages';
  static const String cartItemsTable = 'cart_items';
  static const String cartItemModifiersTable = 'cart_item_modifiers';
  static const String tableServiceRequestsTable = 'table_service_requests';
  static const String paymentsTable = 'payments';
  static const String deliveryExceptionsTable = 'delivery_exceptions';
  static const String restaurantsTable = 'restaurants';
  static const String cashDrawerTransactionsTable = 'cash_drawer_transactions';
  static const String heldOrdersTable = 'held_orders';
  static const String operationalAlertsTable = 'operational_alerts';
  static const String staffTimesheetsTable = 'staff_timesheets';
  static const String purchaseOrdersTable = 'purchase_orders';
  static const String guestFeedbacksTable = 'guest_feedbacks';
  static const String salesTargetsTable = 'sales_targets';
  static const String customerDietaryProfilesTable = 'customer_dietary_profiles';
  static const String customerWalletsTable = 'customer_wallets';
  static const String customerWalletTransactionsTable = 'customer_wallet_transactions';
  static const String giftCardsTable = 'gift_cards';
  static const String curbsidePickupsTable = 'curbside_pickups';
  static const String recipesTable = 'recipes';
  static const String wasteLogsTable = 'waste_logs';
  static const String shiftReconciliationsTable = 'shift_reconciliations';

  // ── Storage Buckets ───────────────────────────────────────────────────────
  static const String menuBucket = 'menu-images';
  static const String avatarsBucket = 'user-avatars';
  static const String deliveryProofBucket = 'delivery-proofs';

  // ── Default Restaurant ────────────────────────────────────────────────────
  /// The single restaurant UUID this app instance is tied to.
  static const String defaultRestaurantId =
      '1e08b47c-15be-4604-a913-431af7fbd54f';
}
