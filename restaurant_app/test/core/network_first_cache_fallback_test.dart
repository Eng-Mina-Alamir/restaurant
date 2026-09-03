import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:restaurant_app/core/data/local_cache_service.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/coupons/data/repositories/supabase_coupon_repository.dart';
import 'package:restaurant_app/features/coupons/domain/entities/coupon_entity.dart';
import 'package:restaurant_app/features/inventory/data/repositories/supabase_inventory_repository.dart';
import 'package:restaurant_app/features/inventory/domain/entities/inventory_item_entity.dart';
import 'package:restaurant_app/features/menu/data/repositories/supabase_menu_repository.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/reservations/data/repositories/supabase_reservation_repository.dart';
import 'package:restaurant_app/features/reservations/domain/entities/reservation_entity.dart';
import 'package:restaurant_app/features/table_management/data/repositories/supabase_table_repository.dart';
import 'package:restaurant_app/features/table_management/domain/entities/restaurant_table.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('cache_fallback_test');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<LocalCacheService> freshCache() async {
    final box = await Hive.openBox<String>('cache_test_${DateTime.now().microsecondsSinceEpoch}');
    await box.clear();
    return LocalCacheService(box);
  }

  // Create an offline/dummy SupabaseClient that will fail HTTP queries
  SupabaseClient offlineClient() {
    return SupabaseClient(
      'https://placeholder-offline.supabase.co',
      'invalid-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
  }

  group('CouponEntity JSON Serialization', () {
    test('round-trips percentage coupon correctly', () {
      final coupon = CouponEntity(
        id: 'cpn-test',
        code: 'TEST20',
        title: 'خصم 20%',
        discountType: CouponDiscountType.percentage,
        discountValue: 20.0,
        minOrderAmount: 100.0,
        maxDiscountAmount: 50.0,
        validUntil: DateTime(2026, 12, 31),
        usageLimit: 100,
        usageCount: 15,
        isActive: true,
      );

      final json = coupon.toJson();
      final restored = CouponEntity.fromJson(json);

      expect(restored.id, coupon.id);
      expect(restored.code, coupon.code);
      expect(restored.title, coupon.title);
      expect(restored.discountType, coupon.discountType);
      expect(restored.discountValue, coupon.discountValue);
      expect(restored.minOrderAmount, coupon.minOrderAmount);
      expect(restored.maxDiscountAmount, coupon.maxDiscountAmount);
      expect(restored.usageCount, coupon.usageCount);
      expect(restored.isActive, isTrue);
    });
  });

  group('Network-First with Cache-Fallback Repositories', () {
    test('SupabaseMenuRepository falls back to persistent cache when offline', () async {
      final cache = await freshCache();

      // Pre-populate persistent cache as if a previous online fetch succeeded
      const savedMenu = Menu(
        restaurantId: '1e08b47c-15be-4604-a913-431af7fbd54f',
        categories: ['مشويات', 'طواجن'],
        items: [
          MenuItem(
            id: 'item-real-1',
            categoryId: 'طواجن',
            name: 'طاجن بامية باللحمة الضاني',
            description: 'طاجن فخار أصلي',
            price: 95.0,
          ),
        ],
      );
      await cache.writeString('cached_menu', jsonEncode(savedMenu.toJson()));

      final repo = SupabaseMenuRepositoryImpl(offlineClient(), cache);
      final result = await repo.getMenu();

      expect(result.isRight, isTrue);
      result.when(
        onLeft: (_) => fail('Expected right menu'),
        onRight: (menu) {
          expect(menu.items, hasLength(1));
          expect(menu.items.first.name, 'طاجن بامية باللحمة الضاني');
          expect(menu.categories, contains('طواجن'));
        },
      );
    });

    test('SupabaseTableRepository falls back to persistent cache when offline', () async {
      final cache = await freshCache();

      final savedTables = [
        const RestaurantTable(
          id: 'table-101',
          tableNumber: 101,
          capacity: 6,
          location: 'تراس خارجي رائع',
          status: TableStatus.available,
        ),
      ];
      await cache.writeList('cached_tables', savedTables.map((t) => t.toJson()).toList());

      final repo = SupabaseTableRepository(offlineClient(), cache);
      final result = await repo.getTables();

      expect(result.isRight, isTrue);
      result.when(
        onLeft: (_) => fail('Expected right tables'),
        onRight: (tables) {
          expect(tables, hasLength(1));
          expect(tables.first.id, 'table-101');
          expect(tables.first.tableNumber, 101);
          expect(tables.first.location, 'تراس خارجي رائع');
        },
      );
    });

    test('SupabaseInventoryRepository falls back to persistent cache when offline', () async {
      final cache = await freshCache();

      const savedInventory = [
        InventoryItemEntity(
          id: 'inv-custom-1',
          name: 'لحم ضاني طازج بلدي',
          category: 'لحوم',
          currentStock: 50.0,
          unit: 'كجم',
          minThreshold: 15.0,
          costPerUnit: 350.0,
        ),
      ];
      await cache.writeList('cached_inventory', savedInventory.map((i) => i.toJson()).toList());

      final repo = SupabaseInventoryRepository(supabase: offlineClient(), cache: cache);
      final result = await repo.getInventoryItems();

      expect(result.isRight, isTrue);
      result.when(
        onLeft: (_) => fail('Expected right inventory'),
        onRight: (items) {
          expect(items, hasLength(1));
          expect(items.first.name, 'لحم ضاني طازج بلدي');
          expect(items.first.costPerUnit, 350.0);
        },
      );
    });

    test('SupabaseCouponRepository falls back to persistent cache when offline', () async {
      final cache = await freshCache();

      final savedCoupons = [
        const CouponEntity(
          id: 'cpn-persisted',
          code: 'PERSIST50',
          title: 'خصم أوفلاين 50',
          discountType: CouponDiscountType.fixed,
          discountValue: 50.0,
          minOrderAmount: 200.0,
        ),
      ];
      await cache.writeList('cached_coupons', savedCoupons.map((c) => c.toJson()).toList());

      final repo = SupabaseCouponRepository(supabase: offlineClient(), cache: cache);
      final result = await repo.getCoupons();

      expect(result.isRight, isTrue);
      result.when(
        onLeft: (_) => fail('Expected right coupons'),
        onRight: (coupons) {
          expect(coupons, hasLength(1));
          expect(coupons.first.code, 'PERSIST50');
          expect(coupons.first.discountValue, 50.0);
        },
      );
    });

    test('SupabaseReservationRepository falls back to persistent cache when offline', () async {
      final cache = await freshCache();

      final savedReservations = [
        ReservationEntity(
          id: 'res-custom-1',
          customerName: 'الأستاذ أحمد فؤاد',
          customerPhone: '01012345678',
          tableId: 'table-5',
          tableNumber: 5,
          guestCount: 4,
          reservationTime: DateTime(2026, 9, 3, 20, 0),
          status: ReservationStatus.confirmed,
          createdAt: DateTime.now(),
        ),
      ];
      await cache.writeList('cached_reservations', savedReservations.map((r) => r.toJson()).toList());

      final repo = SupabaseReservationRepository(supabase: offlineClient(), cache: cache);
      final result = await repo.getReservations();

      expect(result.isRight, isTrue);
      result.when(
        onLeft: (_) => fail('Expected right reservations'),
        onRight: (reservations) {
          expect(reservations, hasLength(1));
          expect(reservations.first.customerName, 'الأستاذ أحمد فؤاد');
          expect(reservations.first.guestCount, 4);
        },
      );
    });
  });
}
