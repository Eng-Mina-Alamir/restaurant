import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:restaurant_app/config/supabase_config.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/network/realtime_event.dart';
import 'package:restaurant_app/core/supabase/supabase_realtime_service.dart';
import 'package:restaurant_app/features/chat/data/repositories/in_memory_chat_repository.dart';
import 'package:restaurant_app/features/chat/presentation/controllers/chat_controller.dart';
import 'package:restaurant_app/features/delivery/data/repositories/in_memory_delivery_repository.dart';
import 'package:restaurant_app/features/delivery/presentation/controllers/delivery_controller.dart';
import 'package:restaurant_app/features/delivery/presentation/pages/driver_home_page.dart';
import 'package:restaurant_app/features/orders/data/repositories/in_memory_order_repository.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';

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
  /// the unread-badge counters watched by DriverHomePage cards. The order-repo
  /// override keeps the provider-wired onDelivered hook hermetic — with an
  /// empty local store it skips the parent-order write instead of reaching
  /// Supabase.
  List<Override> offlineOverrides() => [
    deliveryRepositoryProvider.overrideWithValue(InMemoryDeliveryRepository()),
    chatRepositoryProvider.overrideWithValue(InMemoryChatRepository()),
    orderRepositoryProvider.overrideWithValue(InMemoryOrderRepository()),
    supabaseRealtimeServiceProvider.overrideWithValue(_TestRealtimeService()),
  ];

  group('DeliveryController', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(overrides: offlineOverrides());
    });

    tearDown(() {
      container.dispose();
    });

    test('loads seeded assignments for the demo driver', () async {
      container.read(deliveryControllerProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      final state = container.read(deliveryControllerProvider);
      expect(state, hasLength(2));
      expect(state.first.driverId, 'driver-demo');
    });

    test('pending → accepted → inTransit → delivered', () async {
      final controller = container.read(deliveryControllerProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      const id = 'd1';

      expect(
        container
            .read(deliveryControllerProvider)
            .firstWhere((a) => a.id == id)
            .deliveryStatus,
        DeliveryStatus.pending,
      );

      await controller.accept(id);
      expect(
        container
            .read(deliveryControllerProvider)
            .firstWhere((a) => a.id == id)
            .deliveryStatus,
        DeliveryStatus.accepted,
      );

      await controller.start(id);
      expect(
        container
            .read(deliveryControllerProvider)
            .firstWhere((a) => a.id == id)
            .deliveryStatus,
        DeliveryStatus.inTransit,
      );

      await controller.complete(id);
      expect(
        container
            .read(deliveryControllerProvider)
            .firstWhere((a) => a.id == id)
            .deliveryStatus,
        DeliveryStatus.delivered,
      );
    });

    test('fail marks an assignment as failed', () async {
      final controller = container.read(deliveryControllerProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      const id = 'd1';

      await controller.fail(id);
      expect(
        container
            .read(deliveryControllerProvider)
            .firstWhere((a) => a.id == id)
            .deliveryStatus,
        DeliveryStatus.failed,
      );
    });

    Future<void> broadcastAssignment(Map<String, dynamic> payload) async {
      container
          .read(supabaseRealtimeServiceProvider)
          .emit(
            RealtimeEvent(
              type: RealtimeEventType.deliveryAssignmentCreated,
              payload: payload,
            ),
          );
      await Future<void>.delayed(Duration.zero);
    }

    test(
      'realtime deliveryAssignmentCreated appends the assignment for the matching driver',
      () async {
        // Eagerly instantiate the controller so it listens to the stream.
        container.read(deliveryControllerProvider.notifier);
        await Future<void>.delayed(Duration.zero);

        expect(container.read(deliveryControllerProvider), hasLength(2));

        await broadcastAssignment(assignmentJson(id: 'assign-rt-new'));

        final state = container.read(deliveryControllerProvider);
        expect(state, hasLength(3));
        expect(state.last.id, 'assign-rt-new');
        expect(state.last.orderId, 'ORD-0200');
        expect(state.last.deliveryLocation, 'الرياض - حي الملقا');
      },
    );

    test(
      'realtime deliveryAssignmentCreated ignores a duplicate assignment id (no upsert)',
      () async {
        container.read(deliveryControllerProvider.notifier);
        await Future<void>.delayed(Duration.zero);

        await broadcastAssignment(assignmentJson(id: 'assign-rt-dup'));
        expect(container.read(deliveryControllerProvider), hasLength(3));

        await broadcastAssignment(
          assignmentJson(
            id: 'assign-rt-dup',
            orderId: 'ORD-CHANGED-SHOULD-BE-IGNORED',
          ),
        );

        final state = container.read(deliveryControllerProvider);
        expect(state.where((a) => a.id == 'assign-rt-dup'), hasLength(1));
        expect(state, hasLength(3));
      },
    );

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
