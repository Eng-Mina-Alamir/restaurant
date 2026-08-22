/// Lightweight, immutable driver profile used by dispatch screens.
///
/// Intentionally a plain class (no codegen): it is a read model assembled from
/// `profiles` rows plus an active-assignment count, never round-tripped as
/// JSON by itself.
class DriverInfo {
  const DriverInfo({
    required this.id,
    required this.name,
    this.phone,
    required this.rating,
    this.vehicleInfo,
    this.latitude = 0,
    this.longitude = 0,
    this.activeAssignments = 0,
    this.isAvailable = true,
  });

  final String id;
  final String name;

  /// Contact number for coordination; null when the profile has none.
  final String? phone;

  /// Driver quality rating (1.0–5.0).
  final double rating;
  final String? vehicleInfo;
  final double latitude;
  final double longitude;

  /// Number of non-terminal assignments currently held by this driver.
  final int activeAssignments;
  final bool isAvailable;

  /// True when the driver can take another run right now.
  bool get canTakeAssignment => isAvailable && activeAssignments == 0;

  /// Tolerant factory: missing keys / null values never throw.
  factory DriverInfo.fromMap(Map<String, dynamic> map) {
    return DriverInfo(
      id: map['id']?.toString() ?? '',
      name:
          (map['name'] ?? map['full_name'])?.toString() ?? 'سائق غير معروف',
      phone: map['phone']?.toString(),
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      vehicleInfo: map['vehicle_info']?.toString(),
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      activeAssignments: (map['active_assignments'] as num?)?.toInt() ?? 0,
      isAvailable: map['is_available'] as bool? ?? true,
    );
  }

  @override
  String toString() =>
      'DriverInfo(id: $id, name: $name, rating: $rating, '
      'activeAssignments: $activeAssignments, isAvailable: $isAvailable)';
}
