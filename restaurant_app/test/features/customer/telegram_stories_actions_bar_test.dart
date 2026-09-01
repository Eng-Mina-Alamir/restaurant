import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/customer/presentation/pages/customer_home_page.dart';
import 'package:restaurant_app/features/customer/presentation/widgets/telegram_stories_actions_bar.dart';
import 'package:restaurant_app/features/menu/data/menu_seed_data.dart';

void main() {
  testWidgets('Quick Actions Hub toggles Telegram Stories tray on tap and pull down', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Pre-seed cart with 3 items
    final simpleItem = MenuSeedData.items.firstWhere((i) => i.modifierGroups.isEmpty);
    container.read(cartControllerProvider.notifier).addItem(CartItem(menuItem: simpleItem, quantity: 3));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: CustomerHomePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. In collapsed state: Quick Actions Hub button is present with badge '3' and 'الخدمات'
    expect(find.text('الخدمات'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    // 2. Tap the Hub button to expand Telegram Stories
    await tester.tap(find.text('الخدمات'));
    await tester.pumpAndSettle();

    // 3. All 7 story circle labels are now visible
    expect(find.byType(TelegramStoriesActionsBar), findsOneWidget);
    expect(find.text('مسح QR'), findsOneWidget);
    expect(find.text('المكافآت'), findsOneWidget);
    expect(find.text('الطلبات'), findsOneWidget);
    expect(find.text('التنبيهات'), findsOneWidget);
    expect(find.text('السلة'), findsOneWidget);
    expect(find.text('خروج'), findsOneWidget);

    // 4. Tap the Hub button again to collapse
    await tester.tap(find.text('الخدمات'));
    await tester.pumpAndSettle();

    // 5. Stories tray collapsed
    expect(find.text('المكافآت'), findsNothing);
  });
}
