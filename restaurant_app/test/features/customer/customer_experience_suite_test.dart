import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:restaurant_app/features/customer/presentation/controllers/group_order_controller.dart';
import 'package:restaurant_app/features/customer/presentation/pages/group_order_room_page.dart';
import 'package:restaurant_app/features/customer/presentation/pages/gift_cards_hub_page.dart';
import 'package:restaurant_app/features/customer/presentation/pages/customer_dietary_profile_page.dart';
import 'package:restaurant_app/features/customer/presentation/widgets/dine_in_table_hub_sheet.dart';
import 'package:restaurant_app/features/customer/presentation/widgets/schedule_time_picker_sheet.dart';
import 'package:restaurant_app/features/customer/presentation/widgets/curbside_pickup_sheet.dart';

Widget _buildTestApp({required Widget child, List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    ),
  );
}

void main() {
  group('Customer Experience Suite Widget Tests', () {
    testWidgets('GroupOrderRoomPage displays empty creation state when no session', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: const GroupOrderRoomPage(),
          overrides: [
            groupOrderControllerProvider.overrideWith((ref) => GroupOrderController(ref.watch(groupOrderServiceProvider))),
          ],
        ),
      );
      await tester.pump();

      expect(find.text('غرفة الطلب الجماعي (Group Order)'), findsOneWidget);
      expect(find.text('اطلبوا معاً بسلة واحدة وفاتورة مقسمة!'), findsOneWidget);
      expect(find.text('إنشاء غرفة جديدة'), findsOneWidget);
      expect(find.text('الانضمام بكود الغرفة'), findsOneWidget);
    });

    testWidgets('GroupOrderRoomPage displays active session and members', (tester) async {
      final container = ProviderContainer();
      final controller = container.read(groupOrderControllerProvider.notifier);
      controller.createRoom(
        hostId: 'host-1',
        hostName: 'كيرلس سمير',
        restaurantId: 'rest-1',
        customCode: 'GRP999',
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            locale: Locale('ar'),
            supportedLocales: [Locale('ar'), Locale('en')],
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: GroupOrderRoomPage(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('غرفة الطلب الجماعي نشطة'), findsOneWidget);
      expect(find.text('GRP999'), findsOneWidget);
      expect(find.text('كيرلس سمير'), findsOneWidget);
      expect(find.text('طريقة سداد الفاتورة الجماعية:'), findsOneWidget);
    });

    testWidgets('GiftCardsHubPage displays active cards and action buttons', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(child: const GiftCardsHubPage()),
      );
      await tester.pump();

      expect(find.text('بطاقات الهدايا الرقمية (Gift Cards)'), findsOneWidget);
      expect(find.text('أهدِ أحباءك أشهى اللحظات!'), findsOneWidget);
      expect(find.text('إرسال بطاقة هدية جديدة'), findsOneWidget);
      expect(find.text('شحن كود'), findsWidgets);
      expect(find.text('GIFT-GOLD-8821-VVIP'), findsOneWidget);
    });

    testWidgets('CustomerDietaryProfilePage allows toggling allergens and goals', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(child: const CustomerDietaryProfilePage()),
      );
      await tester.pump();

      expect(find.text('الملف الصحي والحساسية الغذائية'), findsOneWidget);
      expect(find.text('الهدف والنمط الغذائي المفضل:'), findsOneWidget);
      expect(find.text('كيتو دايت (Keto)'), findsOneWidget);
      expect(find.text('نباتي صرف (Vegan)'), findsOneWidget);
      expect(find.text('فول سوداني'), findsOneWidget);
      expect(find.text('مشتقات حليب ولاكتوز'), findsOneWidget);

      // Tap on Vegan dietary goal
      await tester.tap(find.text('نباتي صرف (Vegan)'));
      await tester.pump();

      // Tap on Peanut allergen filter chip
      await tester.ensureVisible(find.text('فول سوداني'));
      await tester.tap(find.text('فول سوداني'), warnIfMissed: false);
      await tester.pump();
    });

    testWidgets('DineInTableHubSheet renders all service actions', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: const Scaffold(
            body: DineInTableHubSheet(
              tableNumber: 7,
              tableId: 'tbl-7',
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('خدمات طاولة رقم #7'), findsOneWidget);
      expect(find.text('استدعاء الويتر'), findsOneWidget);
      expect(find.text('طلب الفاتورة'), findsOneWidget);
      expect(find.text('تنظيف الطاولة'), findsOneWidget);
      expect(find.text('ماء ومناديل'), findsOneWidget);
    });

    testWidgets('ScheduleTimePickerSheet renders day offsets and time slots', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: const Scaffold(
            body: ScheduleTimePickerSheet(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('تحديد موعد استلام الطلب'), findsOneWidget);
      expect(find.text('اليوم'), findsOneWidget);
      expect(find.text('غداً'), findsOneWidget);
      expect(find.text('بعد غد'), findsOneWidget);
      expect(find.text('تأكيد موعد الجدولة'), findsOneWidget);
    });

    testWidgets('CurbsidePickupSheet renders vehicle input fields', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: const Scaffold(
            body: CurbsidePickupSheet(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('بيانات استلام الوجبة من السيارة'), findsOneWidget);
      expect(find.text('تأكيد بيانات السيارة'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(4));
    });
  });
}
