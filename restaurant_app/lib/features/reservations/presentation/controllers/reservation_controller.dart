import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/app_config.dart';
import '../../../../core/data/app_cache.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../domain/entities/reservation_entity.dart';
import '../../domain/repositories/reservation_repository.dart';
import '../../data/repositories/in_memory_reservation_repository.dart';
import '../../data/repositories/supabase_reservation_repository.dart';
import '../../../table_management/presentation/controllers/table_controller.dart';

final reservationRepositoryProvider = Provider<ReservationRepository>((ref) {
  if (AppConfig.useSupabase) {
    return SupabaseReservationRepository(
      supabase: ref.watch(supabaseClientProvider),
      cache: ref.watch(localCacheServiceProvider),
    );
  }
  return InMemoryReservationRepository();
});

class ReservationController
    extends StateNotifier<AsyncValue<List<ReservationEntity>>> {
  ReservationController(this._repository, this._ref)
    : super(const AsyncValue.loading()) {
    loadReservations();
  }

  final ReservationRepository _repository;
  final Ref _ref;

  Future<void> loadReservations() async {
    state = const AsyncValue.loading();
    final result = await _repository.getReservations();
    result.when(
      onLeft: (failure) =>
          state = AsyncValue.error(failure, StackTrace.current),
      onRight: (data) => state = AsyncValue.data(data),
    );
  }

  Future<bool> createReservation({
    required String customerName,
    required String customerPhone,
    required String tableId,
    required int tableNumber,
    required int guestCount,
    required DateTime reservationTime,
    String? notes,
  }) async {
    final reservation = ReservationEntity(
      id: '0',
      customerName: customerName,
      customerPhone: customerPhone,
      tableId: tableId,
      tableNumber: tableNumber,
      guestCount: guestCount,
      reservationTime: reservationTime,
      notes: notes,
      status: ReservationStatus.confirmed,
      createdAt: DateTime.now(),
    );

    final result = await _repository.createReservation(reservation);
    return result.when(
      onLeft: (_) => false,
      onRight: (created) {
        // Also update table status to reserved
        _ref
            .read(tableControllerProvider.notifier)
            .setReserved(tableId, reserved: true);
        loadReservations();
        return true;
      },
    );
  }

  Future<void> seatCustomer(ReservationEntity reservation) async {
    await _repository.updateStatus(reservation.id, ReservationStatus.seated);
    // Occupy table
    await _ref
        .read(tableControllerProvider.notifier)
        .occupy(reservation.tableId, orderId: 'RES-SEATED');
    loadReservations();
  }

  Future<void> cancelReservation(ReservationEntity reservation) async {
    await _repository.cancelReservation(reservation.id);
    await _ref
        .read(tableControllerProvider.notifier)
        .setReserved(reservation.tableId, reserved: false);
    loadReservations();
  }
}

final reservationControllerProvider =
    StateNotifierProvider<
      ReservationController,
      AsyncValue<List<ReservationEntity>>
    >((ref) {
      return ReservationController(
        ref.watch(reservationRepositoryProvider),
        ref,
      );
    });
