import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/supabase_config.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/delivery_assignment.dart';
import '../../domain/entities/driver_info.dart';
import '../../domain/repositories/delivery_repository.dart';

/// Supabase-backed [DeliveryRepository].
///
/// Reads/writes the `delivery_assignments` dispatch table and enriches
/// assignments with the driver's profile via a foreign-table join.
class SupabaseDeliveryRepository implements DeliveryRepository {
  SupabaseDeliveryRepository({required SupabaseClient supabase})
    : _supabase = supabase;

  final SupabaseClient _supabase;

  /// Join that embeds the driver profile through the table's FK constraint.
  static const String _selectWithDriver =
      '*, driver:profiles!delivery_assignments_driver_id_fkey'
      '(name, phone, rating, vehicle_info)';

  /// Delivery statuses that free a driver for new work.
  static const List<String> _terminalStatuses = <String>[
    'delivered',
    'failed',
  ];

  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static String? _sanitizeUuid(String? input, {String? defaultFallback}) {
    if (input == null || input.isEmpty) return defaultFallback;
    if (_uuidRegex.hasMatch(input)) return input;
    return defaultFallback;
  }

  @override
  Future<Either<Failure, DeliveryAssignment>> createAssignment(
    DeliveryAssignment assignment,
  ) async {
    try {
      final driverId = _sanitizeUuid(assignment.driverId);
      if (driverId == null) {
        return const Left<Failure, DeliveryAssignment>(
          ValidationFailure('معرّف السائق غير صالح للإرسال للسيرفر'),
        );
      }
      await _supabase
          .from(SupabaseConfig.deliveryAssignmentsTable)
          .upsert(_assignmentToRow(assignment, driverId));
      return Right<Failure, DeliveryAssignment>(assignment);
    } catch (e) {
      AppLogger.error(
        'Supabase createAssignment error: $e '
        '(orderId=${assignment.orderId}, driverId=${assignment.driverId})',
      );
      return Left<Failure, DeliveryAssignment>(
        ServerFailure('فشل إنشاء مهمة التوصيل في السيرفر: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, DeliveryAssignment?>> getAssignmentByOrderId(
    String orderId,
  ) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.deliveryAssignmentsTable)
          .select(_selectWithDriver)
          .eq('order_id', orderId)
          .limit(1);
      final rows = response as List;
      if (rows.isEmpty) {
        return const Right<Failure, DeliveryAssignment?>(null);
      }
      return Right<Failure, DeliveryAssignment?>(
        _assignmentFromRow(Map<String, dynamic>.from(rows.first as Map)),
      );
    } catch (e) {
      AppLogger.error(
        'Supabase getAssignmentByOrderId error: $e (orderId=$orderId)',
      );
      return Left<Failure, DeliveryAssignment?>(
        ServerFailure('فشل جلب مهمة التوصيل: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, List<DriverInfo>>> getAvailableDrivers() async {
    try {
      // 1. Available driver profiles (profiles has no coordinates columns;
      //    live GPS lives in driver_locations and is out of scope here).
      final profilesResponse = await _supabase
          .from(SupabaseConfig.profilesTable)
          .select('id, name, phone, rating, vehicle_info, is_available')
          .eq('role', 'driver')
          .eq('is_available', true);

      // 2. Active (non-terminal) assignments grouped by driver_id.
      final activeResponse = await _supabase
          .from(SupabaseConfig.deliveryAssignmentsTable)
          .select('driver_id')
          .not('delivery_status', 'in', '(${_terminalStatuses.join(',')})');

      final activeCounts = <String, int>{};
      for (final raw in (activeResponse as List)) {
        final map = Map<String, dynamic>.from(raw as Map);
        final driverId = map['driver_id']?.toString();
        if (driverId != null) {
          activeCounts[driverId] = (activeCounts[driverId] ?? 0) + 1;
        }
      }

      final drivers = (profilesResponse as List).map((raw) {
        final map = Map<String, dynamic>.from(raw as Map);
        final driver = DriverInfo.fromMap(map);
        return DriverInfo(
          id: driver.id,
          name: driver.name,
          phone: driver.phone,
          rating: driver.rating,
          vehicleInfo: driver.vehicleInfo,
          latitude: driver.latitude,
          longitude: driver.longitude,
          activeAssignments:
              activeCounts[map['id']?.toString()] ?? driver.activeAssignments,
          isAvailable: driver.isAvailable,
        );
      }).toList();

      return Right<Failure, List<DriverInfo>>(drivers);
    } catch (e) {
      AppLogger.error('Supabase getAvailableDrivers error: $e');
      return Left<Failure, List<DriverInfo>>(
        ServerFailure('فشل جلب السائقين المتاحين: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, List<DeliveryAssignment>>> getAssignments(
    String driverId,
  ) async {
    try {
      // driver_id is a UUID column; a non-UUID id can never match a row.
      final driverUuid = _sanitizeUuid(driverId);
      if (driverUuid == null) {
        return const Right<Failure, List<DeliveryAssignment>>([]);
      }
      final response = await _supabase
          .from(SupabaseConfig.deliveryAssignmentsTable)
          .select(_selectWithDriver)
          .eq('driver_id', driverUuid)
          .order('assigned_at', ascending: false);
      final assignments = (response as List)
          .map(
            (raw) => _assignmentFromRow(Map<String, dynamic>.from(raw as Map)),
          )
          .toList();
      return Right<Failure, List<DeliveryAssignment>>(assignments);
    } catch (e) {
      AppLogger.error(
        'Supabase getAssignments error: $e (driverId=$driverId)',
      );
      return Left<Failure, List<DeliveryAssignment>>(
        ServerFailure('فشل جلب مهام التوصيل: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, DeliveryAssignment>> updateAssignment(
    DeliveryAssignment assignment,
  ) async {
    try {
      final driverId = _sanitizeUuid(assignment.driverId);
      await _supabase
          .from(SupabaseConfig.deliveryAssignmentsTable)
          .update({
            if (driverId != null) 'driver_id': driverId,
            'pickup_time': assignment.pickupTime.toIso8601String(),
            'delivered_time': assignment.deliveredTime?.toIso8601String(),
            'delivery_location': assignment.deliveryLocation,
            'customer_phone': assignment.customerPhone,
            'latitude': assignment.latitude,
            'longitude': assignment.longitude,
            'delivery_status': assignment.deliveryStatus.name,
            'delivery_fee': assignment.deliveryFee,
            'route_distance_meters': assignment.routeDistanceMeters,
            'route_optimized': assignment.routeOptimized,
          })
          .eq('id', assignment.id);
      return Right<Failure, DeliveryAssignment>(assignment);
    } catch (e) {
      AppLogger.error(
        'Supabase updateAssignment error: $e '
        '(assignmentId=${assignment.id}, orderId=${assignment.orderId}, '
        'driverId=${assignment.driverId})',
      );
      return Left<Failure, DeliveryAssignment>(
        ServerFailure('فشل تحديث مهمة التوصيل: $e'),
      );
    }
  }

  Map<String, dynamic> _assignmentToRow(
    DeliveryAssignment a,
    String sanitizedDriverId,
  ) => <String, dynamic>{
    'id': a.id,
    'order_id': a.orderId,
    'driver_id': sanitizedDriverId,
    'pickup_time': a.pickupTime.toIso8601String(),
    'delivered_time': a.deliveredTime?.toIso8601String(),
    'delivery_location': a.deliveryLocation,
    'customer_phone': a.customerPhone,
    'latitude': a.latitude,
    'longitude': a.longitude,
    'delivery_status': a.deliveryStatus.name,
    'delivery_fee': a.deliveryFee,
    'route_distance_meters': a.routeDistanceMeters,
    if (a.assignedAt != null) 'assigned_at': a.assignedAt!.toIso8601String(),
    'assignment_method': a.assignmentMethod,
  };

  DeliveryAssignment _assignmentFromRow(Map<String, dynamic> map) {
    final dynamic driverRaw = map['driver'];
    final driverMap = driverRaw is Map
        ? Map<String, dynamic>.from(driverRaw)
        : const <String, dynamic>{};
    return DeliveryAssignment(
      id: map['id']?.toString() ?? '',
      orderId: map['order_id']?.toString() ?? '',
      driverId: map['driver_id']?.toString() ?? '',
      pickupTime: map['pickup_time'] != null
          ? DateTime.tryParse(map['pickup_time'].toString()) ??
                DateTime.now()
          : DateTime.now(),
      deliveredTime: map['delivered_time'] == null
          ? null
          : DateTime.tryParse(map['delivered_time'].toString()),
      deliveryLocation: map['delivery_location']?.toString() ?? '',
      customerPhone: map['customer_phone']?.toString(),
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      deliveryStatus: DeliveryStatus.fromName(
        map['delivery_status'] as String?,
      ),
      deliveryFee: (map['delivery_fee'] as num?)?.toDouble(),
      routeOptimized: map['route_optimized']?.toString(),
      routeDistanceMeters:
          (map['route_distance_meters'] as num?)?.toDouble(),
      driverName: driverMap['name']?.toString(),
      driverPhone: driverMap['phone']?.toString(),
      driverRating: (driverMap['rating'] as num?)?.toDouble(),
      vehicleInfo: driverMap['vehicle_info']?.toString(),
      assignmentMethod: map['assignment_method']?.toString() ?? 'auto',
      assignedAt: map['assigned_at'] == null
          ? null
          : DateTime.tryParse(map['assigned_at'].toString()),
    );
  }
}
