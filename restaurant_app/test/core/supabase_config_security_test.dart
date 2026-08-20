import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/config/supabase_config.dart';

void main() {
  group('Supabase Configuration Security & Schema Tests', () {
    test('Supabase URL is valid HTTPS endpoint', () {
      expect(SupabaseConfig.url, isNotEmpty);
      expect(SupabaseConfig.url, startsWith('https://'));
      final uri = Uri.tryParse(SupabaseConfig.url);
      expect(uri, isNotNull);
      expect(uri?.host, contains('supabase.co'));
    });

    test('Supabase Anon Key is configured properly', () {
      expect(SupabaseConfig.anonKey, isNotEmpty);
      expect(SupabaseConfig.anonKey.length, greaterThan(20));
    });

    test('Supabase table name constants match schema tables', () {
      expect(SupabaseConfig.profilesTable, 'profiles');
      expect(SupabaseConfig.categoriesTable, 'categories');
      expect(SupabaseConfig.menuItemsTable, 'menu_items');
      expect(SupabaseConfig.modifierGroupsTable, 'menu_modifier_groups');
      expect(SupabaseConfig.modifierOptionsTable, 'menu_modifier_options');
      expect(SupabaseConfig.tablesTable, 'tables');
      expect(SupabaseConfig.ordersTable, 'orders');
      expect(SupabaseConfig.orderItemsTable, 'order_items');
      expect(SupabaseConfig.reservationsTable, 'reservations');
      expect(SupabaseConfig.couponsTable, 'coupons');
      expect(SupabaseConfig.ratingsTable, 'ratings');
      expect(SupabaseConfig.inventoryTable, 'inventory');
      expect(SupabaseConfig.driverLocationsTable, 'driver_locations');
    });

    test('Supabase storage buckets match storage configuration', () {
      expect(SupabaseConfig.menuBucket, 'menu-images');
      expect(SupabaseConfig.avatarsBucket, 'user-avatars');
      expect(SupabaseConfig.deliveryProofBucket, 'delivery-proofs');
    });
  });
}
