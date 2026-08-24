import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/network/realtime_service.dart';
import 'package:restaurant_app/features/chat/data/repositories/in_memory_chat_repository.dart';
import 'package:restaurant_app/features/chat/presentation/controllers/chat_controller.dart';
import 'package:restaurant_app/features/delivery/data/repositories/in_memory_delivery_repository.dart';
import 'package:restaurant_app/features/delivery/presentation/controllers/delivery_controller.dart';
import 'package:restaurant_app/features/delivery/presentation/pages/driver_home_page.dart';

/// Builds a well-formed deliveryAssignmentCreated payload.
Map<String, dynamic> assignmentJson({
  String id = 'assign-rt-1',
  String orderId = 'ORD-0200',
  String driverId = 'driver-demo',
}) => {
  'id': id,
  'orderId': orderId,
  'driverId': driverId,
  'pickupTime': DateTime.now().toIso8601String(),
  'deliveryLocation': 'الرياض - حي الملقا',
  'deliveryStatus': 'pending',
};

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar');
  });

  /// Keeps tests offline: the shared providers route to Supabase when
  /// AppConfig.useSupabase is enabled (same pattern as orderRepositoryProvider
  /// overrides in test/helpers/test_container.dart). The chat override covers
  /// the unread-badge counters watched by DriverHomePage cards.
  List<Override> offlineOverrides() => [
    deliveryRepositoryProvider.overrideWithValue(InMemoryDeliveryRepository()),
    chatRepositoryProvider.overrideWithValue(InMemoryChatRepository()),
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

  group('realtime deliveryAssignmentCreated', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer(overrides: offlineOverrides()));
    tearDown(() => container.dispose());

    /// The controller and the test read the same shared RealtimeService from
    /// the container; with no socket connected sendEvent loops back into the
    /// events stream, driving the exact path a live dispatch would take.
    Future<void> broadcastAssignment(Map<String, dynamic> json) async {
      container
          .read(realtimeServiceProvider)
          .sendEvent('deliveryAssignmentCreated', json);
      await Future<void>.delayed(Duration.zero);
    }

    test('appends the assignment for the matching driver', () async {
      container.read(deliveryControllerProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(deliveryControllerProvider), hasLength(2));

      await broadcastAssignment(
        assignmentJson(id: 'assign-rt-1', orderId: 'ORD-0200'),
      );

      final state = container.read(deliveryControllerProvider);
      expect(state, hasLength(3));
      expect(state.last.id, 'assign-rt-1');
      expect(state.last.orderId, 'ORD-0200');
      expect(state.last.deliveryStatus, DeliveryStatus.pending);
    });

    test('ignores a duplicate assignment id (no upsert)', () async {
      container.read(deliveryControllerProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      await broadcastAssignment(assignmentJson(id: 'assign-rt-dup'));
      // Same id again but different order: state must stay untouched.
      await broadcastAssignment(
        assignmentJson(id: 'assign-rt-dup', orderId: 'ORD-9999'),
      );

      final state = container.read(deliveryControllerProvider);
      expect(state.where((a) => a.id == 'assign-rt-dup'), hasLength(1));
      expect(state, hasLength(3));
    });

    test('ignores assignments dispatched to another driver', () async {
      container.read(deliveryControllerProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      await broadcastAssignment(assignmentJson(driverId: 'driver-other'));

      final state = container.read(deliveryControllerProvider);
      expect(state, hasLength(2));
    });

    test('ignores malformed payloads without crashing', () async {
      container.read(deliveryControllerProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      await broadcastAssignment({'unexpected': true});

      // Controller survived and keeps processing later events.
      final state = container.read(deliveryControllerProvider);
      expect(state, hasLength(2));

      await broadcastAssignment(assignmentJson(id: 'assign-rt-after-error'));
      expect(
        container.read(deliveryControllerProvider).last.id,
        'assign-rt-after-error',
      );
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
