import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/reservation_entity.dart';
import '../../domain/repositories/reservation_repository.dart';

class InMemoryReservationRepository implements ReservationRepository {
  InMemoryReservationRepository() {
    _seed();
  }

  final List<ReservationEntity> _reservations = [];

  void _seed() {
    final now = DateTime.now();
    _reservations.addAll([
      ReservationEntity(
        id: 'res-101',
        customerName: 'أحمد محمود عبد العزيز',
        customerPhone: '01012345678',
        tableId: 't1',
        tableNumber: 1,
        guestCount: 2,
        reservationTime: now.add(const Duration(hours: 1)),
        notes: 'طاولة مطلة على النيل مباشرة',
        status: ReservationStatus.confirmed,
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      ReservationEntity(
        id: 'res-102',
        customerName: 'م. مريم خليل',
        customerPhone: '01298765432',
        tableId: 't3',
        tableNumber: 3,
        guestCount: 6,
        reservationTime: now.add(const Duration(hours: 3)),
        notes: 'عزومة عائلية واحتفال نجاح',
        status: ReservationStatus.confirmed,
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      ReservationEntity(
        id: 'res-103',
        customerName: 'د. عصام الشناوي',
        customerPhone: '01155443322',
        tableId: 't5',
        tableNumber: 5,
        guestCount: 4,
        reservationTime: now.subtract(const Duration(hours: 1)),
        notes: 'عشاء عمل مع ضيوف من الإسكندرية',
        status: ReservationStatus.seated,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ]);
  }

  @override
  Future<Either<Failure, List<ReservationEntity>>> getReservations() async {
    final sorted = List<ReservationEntity>.from(_reservations)
      ..sort((a, b) => a.reservationTime.compareTo(b.reservationTime));
    return Right<Failure, List<ReservationEntity>>(sorted);
  }

  @override
  Future<Either<Failure, ReservationEntity>> createReservation(
    ReservationEntity reservation,
  ) async {
    _reservations.add(reservation);
    return Right<Failure, ReservationEntity>(reservation);
  }

  @override
  Future<Either<Failure, ReservationEntity>> updateStatus(
    String id,
    ReservationStatus status,
  ) async {
    final index = _reservations.indexWhere((r) => r.id == id);
    if (index == -1) {
      return const Left(ValidationFailure('الحجز غير موجود'));
    }
    final updated = _reservations[index].copyWith(status: status);
    _reservations[index] = updated;
    return Right<Failure, ReservationEntity>(updated);
  }

  @override
  Future<Either<Failure, void>> cancelReservation(String id) async {
    final index = _reservations.indexWhere((r) => r.id == id);
    if (index != -1) {
      _reservations[index] =
          _reservations[index].copyWith(status: ReservationStatus.cancelled);
    }
    return const Right<Failure, void>(null);
  }
}
