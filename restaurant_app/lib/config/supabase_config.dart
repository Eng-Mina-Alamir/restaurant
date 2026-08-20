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

  // ── Storage Buckets ───────────────────────────────────────────────────────
  static const String menuBucket = 'menu-images';
  static const String avatarsBucket = 'user-avatars';
  static const String deliveryProofBucket = 'delivery-proofs';
}
