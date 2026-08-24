import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/config/supabase_config.dart';
import 'package:restaurant_app/core/supabase/supabase_storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('SupabaseStorageService Unit Tests', () {
    late SupabaseClient client;
    late SupabaseStorageService storageService;

    setUp(() {
      client = SupabaseClient(SupabaseConfig.url, SupabaseConfig.anonKey);
      storageService = SupabaseStorageService(client);
    });

    test('initializes with SupabaseClient without errors', () {
      expect(storageService, isNotNull);
    });

    test(
      'handles upload delivery proof image failure gracefully without throwing uncaught error',
      () async {
        final fakeBytes = Uint8List.fromList([0, 1, 2, 3]);
        final result = await storageService.uploadDeliveryProof(
          orderId: 'ORD-999',
          bytes: fakeBytes,
        );

        // In offline/mocked unit test environment, network upload fails gracefully and returns null
        expect(result, isNull);
      },
    );

    test('handles upload menu item image failure gracefully', () async {
      final fakeBytes = Uint8List.fromList([4, 5, 6, 7]);
      final result = await storageService.uploadMenuItemImage(
        itemId: 'item-10',
        bytes: fakeBytes,
      );

      expect(result, isNull);
    });
  });
}
