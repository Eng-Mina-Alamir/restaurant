import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/config/supabase_config.dart';

void main() {
  group('Supabase Configuration Tests', () {
    test('verifies Supabase URL and anonKey are properly set', () {
      expect(SupabaseConfig.url, isNotEmpty);
      expect(SupabaseConfig.url, startsWith('https://'));
      expect(SupabaseConfig.anonKey, isNotEmpty);
      expect(SupabaseConfig.anonKey, startsWith('sb_publishable_'));
    });

    test('verifies Supabase table names', () {
      expect(SupabaseConfig.profilesTable, 'profiles');
      expect(SupabaseConfig.categoriesTable, 'categories');
      expect(SupabaseConfig.menuItemsTable, 'menu_items');
      expect(SupabaseConfig.ordersTable, 'orders');
      expect(SupabaseConfig.tablesTable, 'tables');
    });

    test('verifies Supabase storage buckets', () {
      expect(SupabaseConfig.menuBucket, 'menu-images');
      expect(SupabaseConfig.avatarsBucket, 'user-avatars');
      expect(SupabaseConfig.deliveryProofBucket, 'delivery-proofs');
    });
  });
}
