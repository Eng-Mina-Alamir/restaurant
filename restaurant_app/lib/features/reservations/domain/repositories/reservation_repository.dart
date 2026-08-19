import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/reservation_entity.dart';

abstract class ReservationRepository {
  Future<Either<Failure, List<ReservationEntity>>> getReservations();
  Future<Either<Failure, ReservationEntity>> createReservation(
    ReservationEntity reservation,
  );
  Future<Either<Failure, ReservationEntity>> updateStatus(
    String id,
    ReservationStatus status,
  );
  Future<Either<Failure, void>> cancelReservation(String id);
}
