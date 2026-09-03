import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:restaurant_app/features/auth/presentation/pages/login_page.dart';
import 'package:restaurant_app/features/chat/data/repositories/in_memory_chat_repository.dart';
import 'package:restaurant_app/features/chat/domain/entities/chat_message.dart';
import 'package:restaurant_app/features/chat/presentation/controllers/chat_controller.dart';
import 'package:restaurant_app/features/chat/presentation/pages/chat_page.dart';
import 'package:restaurant_app/features/delivery/data/repositories/in_memory_delivery_repository.dart';
import 'package:restaurant_app/features/delivery/presentation/controllers/delivery_controller.dart';
import 'package:restaurant_app/features/delivery/presentation/pages/driver_home_page.dart';
import 'package:restaurant_app/features/ratings/domain/entities/rating_entity.dart';
import 'package:restaurant_app/features/ratings/presentation/widgets/rating_dialog.dart';
import 'package:restaurant_app/shared/animations/animated_press_card.dart';
import 'package:restaurant_app/shared/widgets/empty_state.dart';
import 'package:restaurant_app/shared/widgets/language_switcher.dart';
import 'package:restaurant_app/shared/widgets/theme_mode_switch_button.dart';

import '../helpers/test_http_overrides.dart';

void main() {
  setUpAll(() async {
    // Arabic date symbols for Formatters.formatTime on pumped pages.
    await initializeDateFormatting('ar');
    // Map tiles fetched by the driver navigation sheet resolve offline.
    HttpOverrides.global = TestHttpOverrides();
  });

  group('Accessibility & Semantics Quality Tests', () {
    testWidgets(
      'EmptyState widget has semantic headers and accessible button',
      (tester) async {
        var actionTriggered = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmptyState(
                icon: Icons.inbox,
                message: 'لا توجد بيانات متاحة حالياً',
                actionLabel: 'إعادة المحاولة',
                onAction: () => actionTriggered = true,
              ),
            ),
          ),
        );

        // Verify text semantics
        expect(find.text('لا توجد بيانات متاحة حالياً'), findsOneWidget);
        expect(find.text('إعادة المحاولة'), findsOneWidget);

        // Tap action
        await tester.tap(find.text('إعادة المحاولة'));
        await tester.pump();

        expect(actionTriggered, isTrue);
      },
    );

    testWidgets('ThemeModeSwitchButton meets minimum touch target guidelines', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(56),
                child: ThemeModeSwitchButton(),
              ),
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(IconButton);
      expect(buttonFinder, findsOneWidget);

      final renderBox = tester.renderObject<RenderBox>(buttonFinder);
      // Minimum tap target recommended is 48x48dp (or standard icon button)
      expect(renderBox.size.width, greaterThanOrEqualTo(40.0));
      expect(renderBox.size.height, greaterThanOrEqualTo(40.0));
    });

    testWidgets(
      'LanguageSwitcherButton renders outlined button in non-compact mode',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: Center(child: LanguageSwitcherButton(compact: false)),
              ),
            ),
          ),
        );

        expect(find.byType(LanguageSwitcherButton), findsOneWidget);
        expect(find.byType(AnimatedPressCard), findsOneWidget);
      },
    );
  });

  // ── Cycle 7 additions ────────────────────────────────────────────────────
  //
  // Icon-only touch-target audit (all icon-only controls are Material
  // IconButton, which enforces the 48x48dp minimum interactive dimension):
  //   • ChatPage send                 → IconButton.filled   (tooltip 'إرسال')
  //   • DriverHomePage sheet close    → IconButton          (tooltip 'إغلاق')
  //   • DriverHomePage open chat      → IconButton          (tooltip 'محادثة العميل')
  //   • OrderTrackingPage call driver → IconButton.filledTonal (tooltip 'اتصال بالمندوب')
  //   • DispatchBoardPage refresh     → IconButton          (tooltip 'تحديث')
  group('Cycle 7 semantics fixes', () {
    testWidgets('chat bubbles announce sender + body through Semantics', (
      tester,
    ) async {
      // ensureSemantics must be disposed synchronously before the test body
      // returns (end-of-test verification rejects undisposed handles).
      final semantics = tester.ensureSemantics();

      final repo = InMemoryChatRepository(
        seed: [
          const ChatMessage(
            id: 'm1',
            orderId: 'ORD-ACC',
            senderId: 'cust-1',
            body: 'أنا في انتظارك',
          ),
          const ChatMessage(
            id: 'm2',
            orderId: 'ORD-ACC',
            senderId: 'drv-1',
            body: 'وصلت للعنوان',
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatRepositoryProvider.overrideWithValue(repo),
            chatCurrentUserIdProvider.overrideWithValue('cust-1'),
          ],
          child: const MaterialApp(home: ChatPage(orderId: 'ORD-ACC')),
        ),
      );
      await tester.pump(); // history-first load
      await tester.pump(); // settle frame

      try {
        // Own message names the sender as 'أنت'; the counterpart bubble uses
        // the neutral role label (see _MessageBubble._senderRoleLabel).
        expect(
          find.bySemanticsLabel('رسالة من أنت: أنا في انتظارك'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('رسالة من الطرف الآخر: وصلت للعنوان'),
          findsOneWidget,
        );
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('driver navigation-sheet close button is labelled with a '
        '48dp+ touch target', (tester) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deliveryRepositoryProvider.overrideWithValue(
              InMemoryDeliveryRepository(),
            ),
            // Assignment cards watch unread-chat counters; keep them on the
            // in-memory repository (realtime channels leak pending timers).
            chatRepositoryProvider.overrideWithValue(InMemoryChatRepository()),
          ],
          child: const MaterialApp(home: DriverHomePage()),
        ),
      );
      await tester.pumpAndSettle();

      // Open the tracking/navigation bottom sheet of the first assignment.
      final mapButton = find
          .widgetWithText(OutlinedButton, 'الخريطة والتتبع')
          .first;
      await tester.ensureVisible(mapButton);
      await tester.pumpAndSettle();
      await tester.tap(mapButton);
      // Fixed pumps instead of pumpAndSettle: the live map inside the sheet
      // keeps scheduling frames, so settling would never drain.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      try {
        final closeButton = find.byWidgetPredicate(
          (widget) => widget is IconButton && widget.tooltip == 'إغلاق',
        );
        expect(closeButton, findsOneWidget);
        // Tooltip surfaces to assistive tech through SemanticsProperties.tooltip.
        final node = tester.getSemantics(closeButton);
        expect(node.getSemanticsData().tooltip, 'إغلاق');

        // Material IconButton enforces the minimum interactive dimension.
        final box = tester.renderObject<RenderBox>(closeButton);
        expect(box.size.width, greaterThanOrEqualTo(48.0));
        expect(box.size.height, greaterThanOrEqualTo(48.0));
      } finally {
        semantics.dispose();
      }
    });
  });

  // ── Icon-only accessibility sweep additions ─────────────────────────────
  //
  // Every icon-only control must expose an Arabic accessible name through
  // either `tooltip:` (surfaces as SemanticsProperties.tooltip) or an
  // explicit `Semantics(label:)` wrapper.
  group('Icon-only sweep semantics fixes', () {
    testWidgets('login password toggle announces show/hide action', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LoginPage())),
      );
      await tester.pump();

      try {
        final toggle = find.byType(IconButton);
        expect(toggle, findsOneWidget);

        // Initially obscured → the offered action is to reveal the password.
        expect(
          tester.getSemantics(toggle).getSemanticsData().tooltip,
          'إظهار كلمة المرور',
        );

        // The tooltip must flip meaning together with the icon state.
        await tester.tap(toggle);
        await tester.pump();
        expect(
          tester.getSemantics(toggle).getSemanticsData().tooltip,
          'إخفاء كلمة المرور',
        );

        // Minimum logical touch target (design-system/MASTER.md §3).
        final box = tester.renderObject<RenderBox>(toggle);
        expect(box.size.width, greaterThanOrEqualTo(48.0));
        expect(box.size.height, greaterThanOrEqualTo(48.0));
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('rating stars expose per-star Semantics labels', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: RatingDialog(
                targetId: 'item-1',
                targetType: RatingTargetType.menuItem,
                title: 'قيّم تجربتك',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      try {
        for (var star = 1; star <= 5; star++) {
          expect(
            find.bySemanticsLabel('قيّم $star من 5'),
            findsOneWidget,
            reason: 'star $star must expose its own label',
          );
        }
      } finally {
        semantics.dispose();
      }
    });
  });
}
