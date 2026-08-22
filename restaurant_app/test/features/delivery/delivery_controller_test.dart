import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/delivery/data/repositories/in_memory_delivery_repository.dart';
import 'package:restaurant_app/features/delivery/presentation/controllers/delivery_controller.dart';
import 'package:restaurant_app/features/delivery/presentation/pages/driver_home_page.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar');
  });

  /// Keeps tests offline: the shared provider routes to Supabase when
  /// AppConfig.useSupabase is enabled (same pattern as orderRepositoryProvider
  /// overrides in test/helpers/test_container.dart).
  List<Override> offlineOverrides() => [
        deliveryRepositoryProvider.overrideWithValue(
          InMemoryDeliveryRepository(),
        ),
      ];

  group('DeliveryController', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer(overrides: offlineOverrides()));
    tearDown(() => container.dispose());

    test('loads seeded assignments for the demo driver', () async {
      container.read(deliveryControllerProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(deliveryControllerProvider), hasLength(2));
    });

    test('pending → accepted → inTransit → delivered', () async {
      final controller = container.read(deliveryControllerProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      final id = controller.state.first.id;

      await controller.accept(id);
      expect(controller.state.first.deliveryStatus, DeliveryStatus.accepted);

      await controller.start(id);
      expect(controller.state.first.deliveryStatus, DeliveryStatus.inTransit);

      await controller.complete(id);
      expect(controller.state.first.deliveryStatus, DeliveryStatus.delivered);
      expect(controller.state.first.deliveredTime, isNotNull);
    });

    test('fail marks an assignment as failed', () async {
      final controller = container.read(deliveryControllerProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      final id = controller.state.first.id;

      await controller.fail(id);
      expect(controller.state.first.deliveryStatus, DeliveryStatus.failed);
    });
  });

  testWidgets('driver home renders assignments and actions', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: offlineOverrides(),
        child: const MaterialApp(home: DriverHomePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('#'), findsWidgets);
    expect(find.text('قبول التوصيل'), findsWidgets);
  });
}
