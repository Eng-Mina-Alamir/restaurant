import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/manager_dashboard/presentation/pages/guest_feedback_hub_page.dart';
import 'package:restaurant_app/features/manager_dashboard/presentation/pages/purchase_orders_page.dart';
import 'package:restaurant_app/features/manager_dashboard/presentation/pages/sales_velocity_target_page.dart';
import 'package:restaurant_app/features/manager_dashboard/presentation/pages/security_audit_logs_page.dart';
import 'package:restaurant_app/features/manager_dashboard/presentation/pages/staff_timesheet_page.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_entity.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';

class _FakeOrdersController extends StateNotifier<List<OrderEntity>>
    implements OrdersController {
  _FakeOrdersController() : super([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Manager Operations Suite Widget Tests', () {
    testWidgets('StaffTimesheetPage renders labor cost banner and active staff', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ordersControllerProvider.overrideWith((ref) => _FakeOrdersController()),
          ],
          child: const MaterialApp(
            home: StaffTimesheetPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('حضور وانصراف وتكلفة العمالة (Timesheet)'), findsOneWidget);
      expect(find.text('مؤشر تكلفة العمالة بالنسبة للمبيعات (Labor Cost %)'), findsOneWidget);
      expect(find.text('تسجيل حضور موظف'), findsOneWidget);
    });

    testWidgets('PurchaseOrdersPage renders purchase stats and orders list', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PurchaseOrdersPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('أوامر الشراء والموردين (Purchase Orders)'), findsOneWidget);
      expect(find.text('إجمالي مشتريات المخزون:'), findsOneWidget);
      expect(find.text('أمر شراء جديد'), findsOneWidget);
    });

    testWidgets('SecurityAuditLogsPage renders audit trail and filters', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SecurityAuditLogsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('سجل التدقيق الأمني ومكافحة التلاعب (Audit Trail)'), findsOneWidget);
      expect(find.text('الكل'), findsOneWidget);
      expect(find.text('خطير / تدقيق 🚨'), findsOneWidget);
    });

    testWidgets('GuestFeedbackHubPage renders CSAT score and feedback feed', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: GuestFeedbackHubPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('مركز تقييمات وشكاوى العملاء (Guest CSAT)'), findsOneWidget);
      expect(find.text('مؤشر رضا العملاء العام (CSAT Score)'), findsOneWidget);
    });

    testWidgets('SalesVelocityTargetPage renders target progress and hourly velocity', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ordersControllerProvider.overrideWith((ref) => _FakeOrdersController()),
          ],
          child: const MaterialApp(
            home: SalesVelocityTargetPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('تارجت المبيعات وسرعة البيع بالساعة (Sales Velocity)'), findsOneWidget);
      expect(find.text('إنجاز التارجت اليومي للمطعم (Daily Revenue Target)'), findsOneWidget);
    });
  });
}
