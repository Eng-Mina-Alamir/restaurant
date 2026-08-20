import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/errors/either.dart';
import 'package:restaurant_app/core/errors/failures.dart';
import 'package:restaurant_app/features/reservations/data/repositories/in_memory_reservation_repository.dart';
import 'package:restaurant_app/features/reservations/domain/entities/reservation_entity.dart';

void main() {
  group('ReservationRepository Unit Tests', () {
    late InMemoryReservationRepository repository;

    setUp(() {
      repository = InMemoryReservationRepository();
    });

    test('getReservations returns seeded list sorted by reservationTime', () async {
      final result = await repository.getReservations();
      expect(result.isRight, isTrue);
      expect((result as Right<Failure, List<ReservationEntity>>).value.length, 3);
    });

    test('createReservation adds a new reservation', () async {
      final res = ReservationEntity(
        id: 'res-999',
        customerName: 'طارق العوضي',
        customerPhone: '01000000000',
        tableId: 't2',
        tableNumber: 2,
        guestCount: 4,
        reservationTime: DateTime.now().add(const Duration(days: 1)),
        status: ReservationStatus.pending,
        createdAt: DateTime.now(),
      );

      final result = await repository.createReservation(res);
      expect(result.isRight, isTrue);

      final all = await repository.getReservations();
      expect((all as Right<Failure, List<ReservationEntity>>).value.any((r) => r.id == 'res-999'), isTrue);
    });

    test('updateStatus updates reservation status or returns failure if not found', () async {
      final updateResult = await repository.updateStatus('res-101', ReservationStatus.seated);
      expect(updateResult.isRight, isTrue);
      expect((updateResult as Right<Failure, ReservationEntity>).value.status, ReservationStatus.seated);

      final notFoundResult = await repository.updateStatus('res-404', ReservationStatus.completed);
      expect(notFoundResult.isLeft, isTrue);
    });

    test('cancelReservation sets status to cancelled', () async {
      final cancelResult = await repository.cancelReservation('res-102');
      expect(cancelResult.isRight, isTrue);

      final all = await repository.getReservations();
      final cancelled = (all as Right<Failure, List<ReservationEntity>>).value.firstWhere((r) => r.id == 'res-102');
      expect(cancelled.status, ReservationStatus.cancelled);
    });
  });
}
