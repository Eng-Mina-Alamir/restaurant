import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/errors/either.dart';
import 'package:restaurant_app/core/errors/failures.dart';
import 'package:restaurant_app/core/network/realtime_service.dart';
import 'package:restaurant_app/features/delivery/domain/entities/delivery_assignment.dart';
import 'package:restaurant_app/features/delivery/domain/entities/driver_info.dart';
import 'package:restaurant_app/features/delivery/domain/repositories/delivery_repository.dart';
import 'package:restaurant_app/features/delivery/presentation/controllers/delivery_controller.dart';

class _FakeDeliveryRepository implements DeliveryRepository {
  final List<DeliveryAssignment> assignments = [];

  @override
  Future<Either<Failure, List<DeliveryAssignment>>> getAssignments(String driverId) async {
    return Right(assignments.where((a) => a.driverId == driverId).toList());
  }

  @override
  Future<Either<Failure, DeliveryAssignment>> updateAssignment(DeliveryAssignment assignment) async {
    final index = assignments.indexWhere((a) => a.id == assignment.id);
    if (index != -1) {
      assignments[index] = assignment;
    } else {
      assignments.add(assignment);
    }
    return Right(assignment);
  }

  @override
  Future<Either<Failure, DeliveryAssignment>> createAssignment(DeliveryAssignment assignment) async {
    final index = assignments.indexWhere((a) => a.id == assignment.id);
    if (index != -1) {
      assignments[index] = assignment;
    } else {
      assignments.add(assignment);
    }
    return Right(assignment);
  }

  @override
  Future<Either<Failure, DeliveryAssignment?>> getAssignmentByOrderId(String orderId) async {
    DeliveryAssignment? match;
    for (final a in assignments) {
      if (a.orderId == orderId) {
        match = a;
        break;
      }
    }
    return Right(match);
  }

  @override
  Future<Either<Failure, List<DriverInfo>>> getAvailableDrivers() async {
    return const Right([]);
  }
}

void main() {
  group('DeliveryController Unit Tests', () {
    late _FakeDeliveryRepository repo;
    late RealtimeService realtime;
    late DeliveryController controller;

    setUp(() async {
      repo = _FakeDeliveryRepository();
      repo.assignments.add(
        DeliveryAssignment(
          id: 'del-1',
          orderId: 'ORD-1',
          driverId: 'drv-demo',
          pickupTime: DateTime.now(),
          deliveryLocation: 'مدينة نصر',
          deliveryStatus: DeliveryStatus.pending,
        ),
      );

      realtime = RealtimeService();
      controller = DeliveryController(repo, 'drv-demo', realtimeService: realtime);
      // Wait for initial load
      await Future<void>.delayed(Duration.zero);
    });

    tearDown(() {
      controller.dispose();
      realtime.disconnect();
    });

    test('initial state loads driver assignments', () {
      expect(controller.state, hasLength(1));
      expect(controller.state.first.deliveryStatus, DeliveryStatus.pending);
    });

    test('accept transitions status to accepted', () async {
      await controller.accept('del-1');

      expect(controller.state.first.deliveryStatus, DeliveryStatus.accepted);
      expect(repo.assignments.first.deliveryStatus, DeliveryStatus.accepted);
    });

    test('start transitions status to inTransit', () async {
      await controller.accept('del-1');
      await controller.start('del-1');

      expect(controller.state.first.deliveryStatus, DeliveryStatus.inTransit);
    });

    test('complete transitions status to delivered and stamps deliveredTime', () async {
      await controller.complete('del-1');

      expect(controller.state.first.deliveryStatus, DeliveryStatus.delivered);
      expect(controller.state.first.deliveredTime, isNotNull);
    });

    test('fail transitions status to failed', () async {
      await controller.fail('del-1');

      expect(controller.state.first.deliveryStatus, DeliveryStatus.failed);
    });

    test('updateLocation broadcasts GPS coords', () {
      expectLater(
        realtime.events,
        emits(predicate<RealtimeEvent>((event) {
          return event.type == RealtimeEventType.driverLocationUpdated &&
              event.payload['driverId'] == 'drv-demo' &&
              event.payload['latitude'] == 30.05;
        })),
      );

      controller.updateLocation(latitude: 30.05, longitude: 31.35);
    });
  });
}
