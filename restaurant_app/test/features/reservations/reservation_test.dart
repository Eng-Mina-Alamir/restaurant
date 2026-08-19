import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/reservations/data/repositories/in_memory_reservation_repository.dart';
import 'package:restaurant_app/features/reservations/domain/entities/reservation_entity.dart';

void main() {
  group('Reservation Repository Tests', () {
    late InMemoryReservationRepository repository;

    setUp(() {
      repository = InMemoryReservationRepository();
    });

    test('loads seeded reservations sorted by time', () async {
      final result = await repository.getReservations();
      expect(result.isRight, isTrue);
      final list = result.when(onLeft: (_) => null, onRight: (l) => l);
      expect(list, isNotNull);
      expect(list!.isNotEmpty, isTrue);
    });

    test('creates new reservation successfully', () async {
      final newRes = ReservationEntity(
        id: 'res-test-99',
        customerName: 'فيصل السديري',
        customerPhone: '0555555555',
        tableId: 't5',
        tableNumber: 5,
        guestCount: 4,
        reservationTime: DateTime.now().add(const Duration(days: 1)),
        createdAt: DateTime.now(),
      );

      final result = await repository.createReservation(newRes);
      expect(result.isRight, isTrue);

      final listRes = await repository.getReservations();
      final list = listRes.when(onLeft: (_) => null, onRight: (l) => l);
      expect(list!.any((r) => r.id == 'res-test-99'), isTrue);
    });

    test('updates reservation status and cancels', () async {
      final listRes = await repository.getReservations();
      final firstRes = listRes.when(onLeft: (_) => null, onRight: (l) => l)!.first;

      final updateRes = await repository.updateStatus(firstRes.id, ReservationStatus.seated);
      expect(updateRes.isRight, isTrue);

      await repository.cancelReservation(firstRes.id);
      final updatedListRes = await repository.getReservations();
      final target = updatedListRes.when(onLeft: (_) => null, onRight: (l) => l)!.firstWhere((r) => r.id == firstRes.id);
      expect(target.status, ReservationStatus.cancelled);
    });
  });
}
