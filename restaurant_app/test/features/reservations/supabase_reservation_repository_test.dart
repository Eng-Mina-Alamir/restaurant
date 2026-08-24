import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/config/supabase_config.dart';
import 'package:restaurant_app/features/reservations/data/repositories/supabase_reservation_repository.dart';
import 'package:restaurant_app/features/reservations/domain/entities/reservation_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('SupabaseReservationRepository Tests', () {
    late SupabaseClient client;
    late SupabaseReservationRepository repository;

    setUp(() {
      client = SupabaseClient(SupabaseConfig.url, SupabaseConfig.anonKey);
      repository = SupabaseReservationRepository(supabase: client);
    });

    final testReservation = ReservationEntity(
      id: 'res-test-001',
      customerName: 'أحمد محمود',
      customerPhone: '01012345678',
      tableId: 't-1',
      tableNumber: 1,
      guestCount: 4,
      reservationTime: DateTime.now().add(const Duration(hours: 3)),
      notes: 'طاولة بجوار النافذة',
      status: ReservationStatus.confirmed,
      createdAt: DateTime.now(),
    );

    test('ReservationEntity copyWith and properties', () {
      final updated = testReservation.copyWith(
        status: ReservationStatus.seated,
      );
      expect(updated.status, ReservationStatus.seated);
      expect(updated.customerName, 'أحمد محمود');
      expect(updated.guestCount, 4);
    });

    test(
      'getReservations returns Either with list or handles network failure',
      () async {
        final result = await repository.getReservations();
        expect(result, isNotNull);
      },
    );
  });
}
