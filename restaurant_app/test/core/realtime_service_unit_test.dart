import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/network/realtime_service.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  group('RealtimeEvent Parsing Tests', () {
    test('parses orderCreated event correctly', () {
      final raw = jsonEncode({
        'type': 'orderCreated',
        'data': {'id': 'ORD-001', 'total': 150.0},
      });

      final event = RealtimeEvent.fromRaw(raw);
      expect(event.type, RealtimeEventType.orderCreated);
      expect(event.payload['id'], 'ORD-001');
      expect(event.payload['total'], 150.0);
    });

    test('parses snake_case event names', () {
      final raw = jsonEncode({
        'event': 'order_status_changed',
        'payload': {'orderId': 'ORD-002', 'status': 'preparing'},
      });

      final event = RealtimeEvent.fromRaw(raw);
      expect(event.type, RealtimeEventType.orderStatusChanged);
      expect(event.payload['orderId'], 'ORD-002');
      expect(event.payload['status'], 'preparing');
    });

    test('parses orderReadyForPickup in camelCase', () {
      final raw = jsonEncode({
        'type': 'orderReadyForPickup',
        'data': {'orderId': 'ORD-300', 'tableId': '4'},
      });

      final event = RealtimeEvent.fromRaw(raw);
      expect(event.type, RealtimeEventType.orderReadyForPickup);
      expect(event.payload['orderId'], 'ORD-300');
      expect(event.payload['tableId'], '4');
    });

    test('parses orderReadyForPickup in snake_case', () {
      final raw = jsonEncode({
        'type': 'order_ready_for_pickup',
        'data': {'orderId': 'ORD-301'},
      });

      final event = RealtimeEvent.fromRaw(raw);
      expect(event.type, RealtimeEventType.orderReadyForPickup);
      expect(event.payload['orderId'], 'ORD-301');
    });

    test('parses tableStatusChanged event', () {
      final raw = jsonEncode({
        'type': 'tableStatusChanged',
        'data': {'tableId': 'tbl-1', 'status': 'occupied'},
      });

      final event = RealtimeEvent.fromRaw(raw);
      expect(event.type, RealtimeEventType.tableStatusChanged);
      expect(event.payload['tableId'], 'tbl-1');
    });

    test('parses driverLocationUpdated event', () {
      final raw = jsonEncode({
        'type': 'driver_location_updated',
        'data': {
          'driverId': 'drv-1',
          'latitude': 24.7136,
          'longitude': 46.6753,
        },
      });

      final event = RealtimeEvent.fromRaw(raw);
      expect(event.type, RealtimeEventType.driverLocationUpdated);
      expect(event.payload['latitude'], 24.7136);
    });

    test('unknown type falls back to RealtimeEventType.unknown', () {
      final raw = jsonEncode({
        'type': 'someRandomEvent',
        'data': {'foo': 'bar'},
      });

      final event = RealtimeEvent.fromRaw(raw);
      expect(event.type, RealtimeEventType.unknown);
    });

    test('handles malformed JSON gracefully', () {
      const raw = 'this is not json { [';
      final event = RealtimeEvent.fromRaw(raw);
      expect(event.type, RealtimeEventType.unknown);
      expect(event.payload['raw'], raw);
    });
  });

  group('RealtimeService Loopback Tests', () {
    late RealtimeService service;

    setUp(() {
      service = RealtimeService(wsUrl: 'ws://localhost:9999/ws');
    });

    tearDown(() {
      service.disconnect();
    });

    test(
      'send loops back event to events stream in offline/demo mode',
      () async {
        expectLater(
          service.events,
          emits(
            predicate<RealtimeEvent>((event) {
              return event.type == RealtimeEventType.orderCreated &&
                  event.payload['id'] == 'ORD-999';
            }),
          ),
        );

        service.broadcastOrderCreated({'id': 'ORD-999', 'subtotal': 50.0});
      },
    );

    test('broadcastOrderStatusChanged emits correct event', () async {
      expectLater(
        service.events,
        emits(
          predicate<RealtimeEvent>((event) {
            return event.type == RealtimeEventType.orderStatusChanged &&
                event.payload['orderId'] == 'ORD-100' &&
                event.payload['status'] == 'ready';
          }),
        ),
      );

      service.broadcastOrderStatusChanged('ORD-100', 'ready');
    });

    test('broadcastOrderReadyForPickup emits correct event', () async {
      final at = DateTime.parse('2026-01-01T10:00:00.000');
      expectLater(
        service.events,
        emits(
          predicate<RealtimeEvent>((event) {
            return event.type == RealtimeEventType.orderReadyForPickup &&
                event.payload['orderId'] == 'ORD-200' &&
                event.payload['tableId'] == '7' &&
                event.payload['updatedAt'] == at.toIso8601String();
          }),
        ),
      );

      service.broadcastOrderReadyForPickup(
        'ORD-200',
        tableId: '7',
        updatedAt: at,
      );
    });

    test('broadcastOrderReadyForPickup omits tableId when absent', () async {
      expectLater(
        service.events,
        emits(
          predicate<RealtimeEvent>((event) {
            return event.type == RealtimeEventType.orderReadyForPickup &&
                event.payload.containsKey('tableId') == false;
          }),
        ),
      );

      service.broadcastOrderReadyForPickup('ORD-201');
    });

    test('broadcastTableStatusChanged emits correct event', () async {
      expectLater(
        service.events,
        emits(
          predicate<RealtimeEvent>((event) {
            return event.type == RealtimeEventType.tableStatusChanged &&
                event.payload['id'] == 'tbl-5';
          }),
        ),
      );

      service.broadcastTableStatusChanged({
        'id': 'tbl-5',
        'status': 'available',
      });
    });

    test('broadcastDriverLocation emits correct event', () async {
      expectLater(
        service.events,
        emits(
          predicate<RealtimeEvent>((event) {
            return event.type == RealtimeEventType.driverLocationUpdated &&
                event.payload['driverId'] == 'drv-42' &&
                event.payload['latitude'] == 24.7;
          }),
        ),
      );

      service.broadcastDriverLocation(
        driverId: 'drv-42',
        latitude: 24.7,
        longitude: 46.7,
      );
    });
  });

  group('RealtimeService Disposal Tests', () {
    test(
      'events after disconnect emits done and never resurrects controller',
      () async {
        final service = RealtimeService(wsUrl: 'ws://localhost:9999/ws');
        expect(service.debugHasLiveController, isFalse);

        service.disconnect();

        // Late subscription must not throw and must simply close immediately.
        await expectLater(service.events, emitsDone);
        await expectLater(service.events, emitsDone);

        // Accessing .events post-dispose must not lazily create a fresh
        // (leaked) broadcast controller.
        expect(
          service.debugHasLiveController,
          isFalse,
          reason: '.events resurrected a broadcast controller after disposal',
        );
      },
    );

    test('events after disconnecting a previously-active service also stays '
        'dead', () async {
      final service = RealtimeService(wsUrl: 'ws://localhost:9999/ws');

      // Create the controller while alive, then dispose.
      final activeStream = service.events;
      expect(service.debugHasLiveController, isTrue);
      service.disconnect();
      expect(service.debugHasLiveController, isFalse);

      // Late subscription gets a fresh already-done stream, not the closed
      // controller's stream, and no new open controller appears.
      await expectLater(service.events, emitsDone);
      expect(activeStream, isNot(same(service.events)));
      expect(service.debugHasLiveController, isFalse);
    });

    test('send after disconnect in demo mode does not throw', () {
      final service = RealtimeService(wsUrl: 'ws://localhost:9999/ws');
      service.disconnect();

      // Loop-back target (controller) is closed; send must swallow the
      // StateError via its catch block instead of throwing into teardown.
      expect(
        () => service.broadcastOrderStatusChanged('ORD-1', 'ready'),
        returnsNormally,
      );
    });
  });

  group('RealtimeService Dead Channel Send Tests', () {
    late RealtimeService service;
    late _FakeChannel channel;

    setUp(() {
      service = RealtimeService(wsUrl: 'ws://localhost:9999/ws');
      channel = _FakeChannel(closeCode: 1006);
      // Seam: attach a non-null-but-closed channel without opening a real
      // socket, so send()'s dead-channel path is reachable from tests.
      service.debugChannelForTest = channel;
    });

    tearDown(() {
      service.disconnect();
    });

    test(
      'order broadcast on dead socket warns with orderId and drops message',
      () {
        final warnings = captureWarnings(
          () => service.broadcastOrderStatusChanged('ORD-777', 'ready'),
        );

        expect(warnings, hasLength(1));
        expect(
          warnings.single,
          contains('[Dispatch] outcome=broadcast-dropped reason=socket-dead'),
        );
        expect(warnings.single, contains('orderId=ORD-777'));

        // The dead sink never receives the message – it was dropped, not
        // silently buffered into a closed socket.
        expect(channel.testSink.added, isEmpty);
      },
    );

    test('orderCreated payload falls back to id for orderId tag', () {
      final warnings = captureWarnings(
        () => service.broadcastOrderCreated({'id': 'ORD-888'}),
      );

      expect(warnings, hasLength(1));
      expect(warnings.single, contains('orderId=ORD-888'));
      expect(channel.testSink.added, isEmpty);
    });

    test('non-order broadcast on dead socket uses generic tag', () {
      final warnings = captureWarnings(
        () => service.broadcastTableStatusChanged({
          'id': 'tbl-5',
          'status': 'occupied',
        }),
      );

      expect(warnings, hasLength(1));
      expect(warnings.single, contains('RealtimeService: Broadcast dropped'));
      expect(warnings.single, isNot(contains('[Dispatch]')));
      expect(warnings.single, isNot(contains('orderId=')));
      expect(channel.testSink.added, isEmpty);
    });

    test('unparseable payload still drops with warning and never throws', () {
      final warnings = captureWarnings(
        () => service.send('this is not json { ['),
      );
      expect(warnings, hasLength(1));
      expect(warnings.single, contains('Broadcast dropped'));
      expect(channel.testSink.added, isEmpty);
    });

    test('live attached socket still receives sends with no warning', () {
      final liveChannel = _FakeChannel(closeCode: null);
      service.debugChannelForTest = liveChannel;

      final warnings = captureWarnings(
        () => service.broadcastOrderStatusChanged('ORD-100', 'ready'),
      );

      expect(warnings, isEmpty);
      expect(liveChannel.testSink.added, hasLength(1));
    });
  });
}

/// Runs [action] capturing everything it prints (AppLogger writes via print).
List<String> captureWarnings(void Function() action) {
  final lines = <String>[];
  runZoned(
    action,
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) => lines.add(line),
    ),
  );
  return lines;
}

/// In-memory recording sink implementing the [WebSocketSink] interface.
class _RecordingSink implements WebSocketSink {
  final List<Object> added = [];

  @override
  void add(Object? data) => added.add(data!);

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<Object?> stream) async {}

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {}

  @override
  Future<void> get done => Completer<void>().future;
}

/// Fake [WebSocketChannel] that requires no real sockets. A non-null
/// [closeCode] simulates a closed / failed-handshake socket.
class _FakeChannel extends StreamChannelMixin<Object?>
    implements WebSocketChannel {
  _FakeChannel({required this.closeCode});

  final _RecordingSink testSink = _RecordingSink();

  @override
  final int? closeCode;

  @override
  String? get closeReason => closeCode == null ? null : 'test-closed';

  @override
  String? get protocol => null;

  /// Never completes; nothing consumes it because tests bypass [_doConnect].
  @override
  Future<void> get ready => Completer<void>().future;

  @override
  Stream<Object?> get stream => const Stream<Object?>.empty();

  @override
  WebSocketSink get sink => testSink;
}
