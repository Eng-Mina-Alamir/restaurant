enum ReservationStatus {
  pending,
  confirmed,
  seated,
  cancelled,
  completed;

  String get labelAr {
    switch (this) {
      case ReservationStatus.pending:
        return 'قيد التأكيد';
      case ReservationStatus.confirmed:
        return 'مؤكد';
      case ReservationStatus.seated:
        return 'تم الإجلاس';
      case ReservationStatus.cancelled:
        return 'ملغي';
      case ReservationStatus.completed:
        return 'مكتمل';
    }
  }
}

/// Represents a table reservation in the restaurant.
class ReservationEntity {
  const ReservationEntity({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.tableId,
    required this.tableNumber,
    required this.guestCount,
    required this.reservationTime,
    this.notes,
    this.status = ReservationStatus.confirmed,
    required this.createdAt,
  });

  final String id;
  final String customerName;
  final String customerPhone;
  final String tableId;
  final int tableNumber;
  final int guestCount;
  final DateTime reservationTime;
  final String? notes;
  final ReservationStatus status;
  final DateTime createdAt;

  ReservationEntity copyWith({
    String? id,
    String? customerName,
    String? customerPhone,
    String? tableId,
    int? tableNumber,
    int? guestCount,
    DateTime? reservationTime,
    String? notes,
    ReservationStatus? status,
    DateTime? createdAt,
  }) {
    return ReservationEntity(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      tableId: tableId ?? this.tableId,
      tableNumber: tableNumber ?? this.tableNumber,
      guestCount: guestCount ?? this.guestCount,
      reservationTime: reservationTime ?? this.reservationTime,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'tableId': tableId,
    'tableNumber': tableNumber,
    'guestCount': guestCount,
    'reservationTime': reservationTime.toIso8601String(),
    'notes': notes,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ReservationEntity.fromJson(Map<String, dynamic> json) =>
      ReservationEntity(
        id: json['id'] as String,
        customerName: json['customerName'] as String,
        customerPhone: json['customerPhone'] as String,
        tableId: json['tableId'] as String,
        tableNumber: json['tableNumber'] as int,
        guestCount: json['guestCount'] as int,
        reservationTime: DateTime.parse(json['reservationTime'] as String),
        notes: json['notes'] as String?,
        status: ReservationStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => ReservationStatus.confirmed,
        ),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
