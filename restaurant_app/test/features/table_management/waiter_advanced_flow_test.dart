import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:restaurant_app/config/supabase_config.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/supabase/supabase_realtime_service.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_entity.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_item.dart';
import 'package:restaurant_app/features/table_management/data/repositories/in_memory_table_repository.dart';
import 'package:restaurant_app/features/table_management/domain/entities/restaurant_table.dart';
import 'package:restaurant_app/features/table_management/presentation/controllers/table_controller.dart';
import 'package:restaurant_app/features/table_management/presentation/pages/waiter_tips_page.dart';
import 'package:restaurant_app/features/table_management/presentation/widgets/course_fire_action_bar.dart';
import 'package:restaurant_app/features/table_management/presentation/widgets/split_bill_dialog.dart';
import 'package:restaurant_app/features/table_management/presentation/widgets/table_transfer_dialog.dart';

class _TestRealtimeService extends SupabaseRealtimeService {
  _TestRealtimeService()
    : super(
        SupabaseClient(
          SupabaseConfig.url,
          SupabaseConfig.anonKey,
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );

  @override
  void subscribeForRole(UserRole? role) {}

  @override
  void subscribe() {}
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar');
  });

  final testOrder = OrderEntity(
    id: 'ORD-TEST-1',
    restaurantId: 'rest-1',
    tableId: 'tbl-3',
    orderType: OrderType.dineIn,
    status: OrderStatus.preparing,
    createdAt: DateTime.now(),
    subtotal: 300.0,
    taxAmount: 42.0,
    totalAmount: 378.0,
    items: [
      OrderItem(
        menuItem: const MenuItem(
          id: 'i-1',
          name: 'طاجن عكاوي',
          description: 'طاجن مصري أصيل',
          price: 180.0,
          categoryId: 'cat-main',
        ),
        quantity: 1,
        addedAt: DateTime.now(),
      ),
      OrderItem(
        menuItem: const MenuItem(
          id: 'i-2',
          name: 'كباب وكفتة',
          description: 'مشويات بلدي',
          price: 120.0,
          categoryId: 'cat-main',
        ),
        quantity: 1,
        addedAt: DateTime.now(),
      ),
    ],
  );

  final testTable = RestaurantTable(
    id: 'tbl-3',
    tableNumber: 3,
    capacity: 4,
    status: TableStatus.occupied,
    currentOrderId: 'ORD-TEST-1',
    lastUpdated: DateTime.now(),
  );

  final targetTable = RestaurantTable(
    id: 'tbl-4',
    tableNumber: 4,
    capacity: 6,
    status: TableStatus.available,
    lastUpdated: DateTime.now(),
  );

  testWidgets('SplitBillDialog renders tabs, guest stepper, and allows share payments', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supabaseRealtimeServiceProvider.overrideWithValue(_TestRealtimeService()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SplitBillDialog(order: testOrder, tableNumber: 3),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('تقسيم شيك طاولة 3'), findsOneWidget);
    expect(find.text('تقسيم متساوي'), findsOneWidget);
    expect(find.text('حسب المقاعد والأصناف'), findsOneWidget);
    expect(find.text('2 أفراد'), findsOneWidget);

    // Increment guest count
    final addButton = find.byIcon(Icons.add);
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    expect(find.text('3 أفراد'), findsOneWidget);
  });

  testWidgets('CourseFireActionBar renders course chips and triggers fire action', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supabaseRealtimeServiceProvider.overrideWithValue(_TestRealtimeService()),
          tableRepositoryProvider.overrideWithValue(
            InMemoryTableRepository(seed: [testTable]),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: CourseFireActionBar(
              tableId: 'tbl-3',
              tableNumber: 3,
              orderId: 'ORD-TEST-1',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('توقيت مراحل الطعام'), findsOneWidget);
    expect(find.textContaining('أطباق رئيسية'), findsWidgets);

    final fireButton = find.textContaining('إرسال أمر طهي');
    expect(fireButton, findsOneWidget);

    await tester.tap(fireButton);
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('TableTransferDialog renders transfer and merge tabs', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supabaseRealtimeServiceProvider.overrideWithValue(_TestRealtimeService()),
          tableRepositoryProvider.overrideWithValue(
            InMemoryTableRepository(seed: [testTable, targetTable]),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: TableTransferDialog(
              currentTable: testTable,
              activeOrderId: 'ORD-TEST-1',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('إدارة موقع طاولة 3'), findsOneWidget);
    expect(find.text('نقل الطلب لطاولة أخرى'), findsOneWidget);
    expect(find.text('دمج طاولات (عزومة/مجموعة)'), findsOneWidget);
  });

  testWidgets('WaiterTipsPage renders shift stats, tips breakdown, and closing action', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supabaseRealtimeServiceProvider.overrideWithValue(_TestRealtimeService()),
        ],
        child: const MaterialApp(
          home: WaiterTipsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('تقرير إكراميات وأداء الوردية'), findsOneWidget);
    expect(find.textContaining('إجمالي الإكراميات'), findsOneWidget);
    expect(find.textContaining('تفصيل الإكراميات والتبس'), findsOneWidget);
    expect(find.textContaining('تصفية وإغلاق الوردية'), findsOneWidget);
  });
}
