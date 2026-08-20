import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/reservations/domain/entities/reservation_entity.dart';

void main() {
  group('ReservationEntity Tests', () {
    test('ReservationStatus labels in Arabic', () {
      expect(ReservationStatus.pending.labelAr, 'قيد التأكيد');
      expect(ReservationStatus.confirmed.labelAr, 'مؤكد');
      expect(ReservationStatus.seated.labelAr, 'تم الإجلاس');
      expect(ReservationStatus.cancelled.labelAr, 'ملغي');
      expect(ReservationStatus.completed.labelAr, 'مكتمل');
    });

    test('round-trip serialization', () {
      final now = DateTime(2026, 8, 19, 20, 0);
      final reservation = ReservationEntity(
        id: 'res-1',
        customerName: 'محمود سامي',
        customerPhone: '01234567890',
        tableId: 'tbl-2',
        tableNumber: 2,
        guestCount: 4,
        reservationTime: now,
        notes: 'طاولة بجانب النافذة',
        status: ReservationStatus.confirmed,
        createdAt: now.subtract(const Duration(hours: 2)),
      );

      final json = reservation.toJson();
      expect(json['id'], 'res-1');
      expect(json['customerName'], 'محمود سامي');
      expect(json['guestCount'], 4);
      expect(json['status'], 'confirmed');

      final deserialized = ReservationEntity.fromJson(json);
      expect(deserialized.id, 'res-1');
      expect(deserialized.tableNumber, 2);
      expect(deserialized.status, ReservationStatus.confirmed);
      expect(deserialized.notes, 'طاولة بجانب النافذة');
    });

    test('copyWith produces updated clone', () {
      final reservation = ReservationEntity(
        id: 'res-2',
        customerName: 'سارة',
        customerPhone: '01000000000',
        tableId: 'tbl-1',
        tableNumber: 1,
        guestCount: 2,
        reservationTime: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final updated = reservation.copyWith(status: ReservationStatus.seated);
      expect(updated.status, ReservationStatus.seated);
      expect(updated.customerName, 'سارة');
    });
  });
}
