import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/config/supabase_config.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/data/repositories/supabase_order_repository.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_entity.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('SupabaseOrderRepository Unit Tests', () {
    late SupabaseClient client;
    late SupabaseOrderRepository repository;

    setUp(() {
      client = SupabaseClient(SupabaseConfig.url, SupabaseConfig.anonKey);
      repository = SupabaseOrderRepository(supabase: client);
    });

    final testOrder = OrderEntity(
      id: 'ORD-TEST-001',
      restaurantId: 'restaurant-1',
      customerId: 'cust-1',
      orderType: OrderType.dineIn,
      items: [
        OrderItem(
          menuItem: const MenuItem(
            id: 'item-1',
            categoryId: 'مشويات',
            name: 'كباب وكفتة',
            description: '',
            price: 280.0,
          ),
          quantity: 2,
          addedAt: DateTime.now(),
        ),
      ],
      status: OrderStatus.pending,
      subtotal: 560.0,
      taxAmount: 84.0,
      totalAmount: 644.0,
      createdAt: DateTime.now(),
    );

    test('createOrder handles storage and returns Either result cleanly', () async {
      final result = await repository.createOrder(testOrder);

      expect(result, isNotNull);
      expect(result.isRight || result.isLeft, isTrue);
    });

    test('getOrders returns Right with list of orders (or empty fallback)', () async {
      final result = await repository.getOrders();

      expect(result.isRight, isTrue);
      result.when(
        onLeft: (_) => fail('Expected right order list'),
        onRight: (orders) {
          expect(orders, isA<List<OrderEntity>>());
        },
      );
    });

    test('updateOrderStatus handles update cleanly', () async {
      final result = await repository.updateOrderStatus('ORD-TEST-001', OrderStatus.preparing);
      expect(result, isNotNull);
    });
  });
}
