import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/di/service_locator.dart';
import 'package:restaurant_app/features/auth/data/datasources/supabase_auth_datasource.dart';
import 'package:restaurant_app/features/menu/data/repositories/supabase_menu_repository.dart';
import 'package:restaurant_app/features/orders/data/repositories/supabase_order_repository.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';
import 'package:restaurant_app/features/table_management/data/repositories/supabase_table_repository.dart';
import 'package:restaurant_app/features/table_management/presentation/controllers/table_controller.dart';

void main() {
  group('ServiceLocator & Riverpod Providers Dependency Injection Tests', () {
    test('Production mode binds SupabaseAuthRemoteDataSourceImpl', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final authDatasource = container.read(authRemoteDataSourceProvider);
      expect(authDatasource, isA<SupabaseAuthRemoteDataSourceImpl>());
    });

    test('Production mode binds SupabaseMenuRepositoryImpl', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final menuRepo = container.read(menuRepositoryProvider);
      expect(menuRepo, isA<SupabaseMenuRepositoryImpl>());
    });

    test('Production mode binds SupabaseOrderRepository', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final orderRepo = container.read(orderRepositoryProvider);
      expect(orderRepo, isA<SupabaseOrderRepository>());
    });

    test('Production mode binds SupabaseTableRepository', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final tableRepo = container.read(tableRepositoryProvider);
      expect(tableRepo, isA<SupabaseTableRepository>());
    });
  });
}
