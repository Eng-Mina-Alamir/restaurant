import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/supabase_config.dart';
import '../../../../core/data/local_cache_service.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/alert_entity.dart';
import '../../domain/entities/guest_feedback_entity.dart';
import '../../domain/entities/purchase_order_entity.dart';
import '../../domain/entities/staff_timesheet_entity.dart';

/// Supabase-backed repository for manager operations: alerts, staff timesheets,
/// purchase orders, customer complaint resolutions, and hourly sales velocity targets.
class SupabaseManagerOperationsRepository {
  SupabaseManagerOperationsRepository({
    required SupabaseClient supabase,
    LocalCacheService? cache,
  })  : _supabase = supabase,
        _cache = cache;

  final SupabaseClient _supabase;
  final LocalCacheService? _cache;

  static const String _alertsCacheKey = 'mgr_alerts_v1';
  static const String _timesheetsCacheKey = 'mgr_timesheets_v1';
  static const String _purchaseOrdersCacheKey = 'mgr_pos_v1';
  static const String _feedbackCacheKey = 'mgr_feedback_v1';

  // ── Operational Alerts ──────────────────────────────────────────────────────

  Future<Either<Failure, List<AlertEntity>>> getAlerts() async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.operationalAlertsTable)
          .select()
          .order('created_at', ascending: false)
          .limit(50);

      final list = (response as List).map((row) {
        final map = Map<String, dynamic>.from(row as Map);
        return AlertEntity(
          id: map['id']?.toString() ?? '',
          title: map['title'] as String? ?? '',
          message: map['message'] as String? ?? '',
          severity: AlertSeverity.values.firstWhere(
            (s) => s.name == map['severity'],
            orElse: () => AlertSeverity.info,
          ),
          category: AlertCategory.values.firstWhere(
            (c) => c.name == map['category'],
            orElse: () => AlertCategory.system,
          ),
          createdAt: map['created_at'] != null
              ? DateTime.parse(map['created_at'] as String)
              : DateTime.now(),
          isRead: map['is_read'] as bool? ?? false,
        );
      }).toList();

      final cache = _cache;
      if (cache != null) {
        await cache.writeList(
          _alertsCacheKey,
          list.map((a) => {
            'id': a.id,
            'title': a.title,
            'message': a.message,
            'severity': a.severity.name,
            'category': a.category.name,
            'createdAt': a.createdAt.toIso8601String(),
            'isRead': a.isRead,
          }).toList(),
        );
      }

      return Right(list);
    } catch (e, st) {
      AppLogger.warning('Supabase getAlerts fallback: $e', error: e, stackTrace: st);
      final cache = _cache;
      if (cache != null) {
        final cached = cache.readList(_alertsCacheKey);
        if (cached.isNotEmpty) {
          final list = cached.map((map) {
            return AlertEntity(
              id: map['id']?.toString() ?? '',
              title: map['title'] as String? ?? '',
              message: map['message'] as String? ?? '',
              severity: AlertSeverity.values.firstWhere(
                (s) => s.name == map['severity'],
                orElse: () => AlertSeverity.info,
              ),
              category: AlertCategory.values.firstWhere(
                (c) => c.name == map['category'],
                orElse: () => AlertCategory.system,
              ),
              createdAt: map['createdAt'] != null
                  ? DateTime.parse(map['createdAt'] as String)
                  : DateTime.now(),
              isRead: map['isRead'] as bool? ?? false,
            );
          }).toList();
          return Right(list);
        }
      }
      return const Right([]);
    }
  }

  Future<Either<Failure, AlertEntity>> addAlert(AlertEntity alert) async {
    try {
      final payload = {
        'id': alert.id,
        'restaurant_id': SupabaseConfig.defaultRestaurantId,
        'title': alert.title,
        'message': alert.message,
        'severity': alert.severity.name,
        'category': alert.category.name,
        'is_read': alert.isRead,
        'created_at': alert.createdAt.toIso8601String(),
      };

      await _supabase.from(SupabaseConfig.operationalAlertsTable).upsert(payload);
      return Right(alert);
    } catch (e, st) {
      AppLogger.error('Supabase addAlert failed: $e', error: e, stackTrace: st);
      return Left(ServerFailure('فشل إضافة التنبيه: $e'));
    }
  }

  Future<Either<Failure, void>> markAlertAsRead(String alertId) async {
    try {
      await _supabase
          .from(SupabaseConfig.operationalAlertsTable)
          .update({'is_read': true})
          .eq('id', alertId);
      return const Right(null);
    } catch (e, st) {
      AppLogger.error('Supabase markAlertAsRead failed: $e', error: e, stackTrace: st);
      return Left(ServerFailure('فشل تحديث حالة التنبيه: $e'));
    }
  }

  // ── Staff Timesheets ────────────────────────────────────────────────────────

  Future<Either<Failure, List<StaffAttendanceRecord>>> getTimesheets() async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.staffTimesheetsTable)
          .select()
          .order('clock_in', ascending: false);

      final list = (response as List).map((row) {
        final map = Map<String, dynamic>.from(row as Map);
        final roleStr = map['role'] as String? ?? 'waiter';
        final role = UserRole.values.firstWhere(
          (r) => r.name == roleStr,
          orElse: () => UserRole.waiter,
        );

        return StaffAttendanceRecord(
          id: map['id']?.toString() ?? '',
          staffId: map['user_id']?.toString() ?? '',
          staffName: map['staff_name'] as String? ?? 'موظف',
          role: role,
          clockInAt: map['clock_in'] != null
              ? DateTime.parse(map['clock_in'] as String)
              : DateTime.now(),
          clockOutAt: map['clock_out'] != null
              ? DateTime.parse(map['clock_out'] as String)
              : null,
          notes: map['notes'] as String?,
        );
      }).toList();

      final cache = _cache;
      if (cache != null) {
        await cache.writeList(
          _timesheetsCacheKey,
          list.map((t) => {
            'id': t.id,
            'staffId': t.staffId,
            'staffName': t.staffName,
            'role': t.role.name,
            'clockInAt': t.clockInAt.toIso8601String(),
            'clockOutAt': t.clockOutAt?.toIso8601String(),
            'hourlyWage': t.hourlyWage,
            'notes': t.notes,
          }).toList(),
        );
      }

      return Right(list);
    } catch (e, st) {
      AppLogger.warning('Supabase getTimesheets fallback: $e', error: e, stackTrace: st);
      return const Right([]);
    }
  }

  Future<Either<Failure, StaffAttendanceRecord>> saveTimesheet(StaffAttendanceRecord record) async {
    try {
      final payload = {
        'id': record.id,
        'restaurant_id': SupabaseConfig.defaultRestaurantId,
        'user_id': record.staffId,
        'staff_name': record.staffName,
        'role': record.role.name,
        'clock_in': record.clockInAt.toIso8601String(),
        'clock_out': record.clockOutAt?.toIso8601String(),
        'status': record.isActiveOnDuty ? 'onDuty' : 'clockedOut',
        'notes': record.notes,
      };

      await _supabase.from(SupabaseConfig.staffTimesheetsTable).upsert(payload);
      return Right(record);
    } catch (e, st) {
      AppLogger.error('Supabase saveTimesheet failed: $e', error: e, stackTrace: st);
      return Left(ServerFailure('فشل تسجيل الحضور: $e'));
    }
  }

  // ── Purchase Orders ─────────────────────────────────────────────────────────

  Future<Either<Failure, List<PurchaseOrderEntity>>> getPurchaseOrders() async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.purchaseOrdersTable)
          .select()
          .order('order_date', ascending: false);

      final list = (response as List).map((row) {
        final map = Map<String, dynamic>.from(row as Map);
        final itemsRaw = map['items_json'] as List? ?? [];
        final items = itemsRaw.whereType<Map>().map((i) {
          final itemMap = Map<String, dynamic>.from(i);
          return POItem(
            ingredientId: itemMap['ingredientId'] as String? ?? '',
            ingredientName: itemMap['ingredientName'] as String? ?? '',
            unit: itemMap['unit'] as String? ?? 'كجم',
            orderedQuantity: (itemMap['orderedQuantity'] as num?)?.toDouble() ?? 0.0,
            receivedQuantity: (itemMap['receivedQuantity'] as num?)?.toDouble(),
            estimatedUnitPrice: (itemMap['estimatedUnitPrice'] as num?)?.toDouble() ?? 0.0,
            actualUnitPrice: (itemMap['actualUnitPrice'] as num?)?.toDouble(),
          );
        }).toList();

        return PurchaseOrderEntity(
          id: map['id']?.toString() ?? '',
          supplierName: map['supplier_name'] as String? ?? '',
          supplierPhone: map['supplier_phone'] as String? ?? '',
          status: POStatus.values.firstWhere(
            (s) => s.name == map['status'],
            orElse: () => POStatus.draft,
          ),
          orderDate: map['order_date'] != null
              ? DateTime.parse(map['order_date'] as String)
              : DateTime.now(),
          expectedDeliveryDate: map['expected_delivery_date'] != null
              ? DateTime.parse(map['expected_delivery_date'] as String)
              : null,
          receivedAt: map['actual_delivery_date'] != null
              ? DateTime.parse(map['actual_delivery_date'] as String)
              : null,
          items: items,
          notes: map['notes'] as String?,
        );
      }).toList();

      final cache = _cache;
      if (cache != null) {
        await cache.writeList(
          _purchaseOrdersCacheKey,
          list.map((po) => {
            'id': po.id,
            'supplierName': po.supplierName,
            'supplierPhone': po.supplierPhone,
            'status': po.status.name,
            'orderDate': po.orderDate.toIso8601String(),
            'expectedDeliveryDate': po.expectedDeliveryDate?.toIso8601String(),
            'receivedAt': po.receivedAt?.toIso8601String(),
            'items': po.items.map((i) => {
              'ingredientId': i.ingredientId,
              'ingredientName': i.ingredientName,
              'unit': i.unit,
              'orderedQuantity': i.orderedQuantity,
              'receivedQuantity': i.receivedQuantity,
              'estimatedUnitPrice': i.estimatedUnitPrice,
              'actualUnitPrice': i.actualUnitPrice,
            }).toList(),
            'notes': po.notes,
          }).toList(),
        );
      }

      return Right(list);
    } catch (e, st) {
      AppLogger.warning('Supabase getPurchaseOrders fallback: $e', error: e, stackTrace: st);
      return const Right([]);
    }
  }

  Future<Either<Failure, PurchaseOrderEntity>> savePurchaseOrder(PurchaseOrderEntity po) async {
    try {
      final itemsJson = po.items.map((i) => {
        'ingredientId': i.ingredientId,
        'ingredientName': i.ingredientName,
        'unit': i.unit,
        'orderedQuantity': i.orderedQuantity,
        'receivedQuantity': i.receivedQuantity,
        'estimatedUnitPrice': i.estimatedUnitPrice,
        'actualUnitPrice': i.actualUnitPrice,
      }).toList();

      final payload = {
        'id': po.id,
        'restaurant_id': SupabaseConfig.defaultRestaurantId,
        'supplier_name': po.supplierName,
        'supplier_phone': po.supplierPhone,
        'status': po.status.name,
        'order_date': po.orderDate.toIso8601String(),
        'expected_delivery_date': po.expectedDeliveryDate?.toIso8601String(),
        'actual_delivery_date': po.receivedAt?.toIso8601String(),
        'items_json': itemsJson,
        'total_amount': po.totalEstimatedCost,
        'notes': po.notes,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from(SupabaseConfig.purchaseOrdersTable).upsert(payload);
      return Right(po);
    } catch (e, st) {
      AppLogger.error('Supabase savePurchaseOrder failed: $e', error: e, stackTrace: st);
      return Left(ServerFailure('فشل حفظ طلب الشراء: $e'));
    }
  }

  // ── Guest Feedback Resolutions ──────────────────────────────────────────────

  Future<Either<Failure, List<GuestFeedback>>> getGuestFeedbacks() async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.guestFeedbacksTable)
          .select()
          .order('created_at', ascending: false);

      final list = (response as List).map((row) {
        final map = Map<String, dynamic>.from(row as Map);
        return GuestFeedback(
          id: map['id']?.toString() ?? '',
          customerName: map['customer_name'] as String? ?? 'عميل',
          customerPhone: map['customer_phone'] as String? ?? '',
          orderId: map['order_id'] != null ? 'ORD-${map['order_id']}' : 'ORD-0',
          overallRating: (map['overall_rating'] as num?)?.toInt() ?? 5,
          foodQualityRating: (map['food_quality_rating'] as num?)?.toInt() ?? 5,
          serviceSpeedRating: (map['service_speed_rating'] as num?)?.toInt() ?? 5,
          cleanlinessRating: (map['cleanliness_rating'] as num?)?.toInt() ?? 5,
          comment: map['comment'] as String? ?? '',
          createdAt: map['created_at'] != null
              ? DateTime.parse(map['created_at'] as String)
              : DateTime.now(),
          isResolved: map['is_resolved'] as bool? ?? false,
          resolutionNotes: map['resolution_notes'] as String?,
          compensationCouponCode: map['compensation_coupon_code'] as String?,
        );
      }).toList();

      final cache = _cache;
      if (cache != null) {
        await cache.writeList(
          _feedbackCacheKey,
          list.map((f) => {
            'id': f.id,
            'customerName': f.customerName,
            'customerPhone': f.customerPhone,
            'orderId': f.orderId,
            'overallRating': f.overallRating,
            'foodQualityRating': f.foodQualityRating,
            'serviceSpeedRating': f.serviceSpeedRating,
            'cleanlinessRating': f.cleanlinessRating,
            'comment': f.comment,
            'createdAt': f.createdAt.toIso8601String(),
            'isResolved': f.isResolved,
            'resolutionNotes': f.resolutionNotes,
            'compensationCouponCode': f.compensationCouponCode,
          }).toList(),
        );
      }

      return Right(list);
    } catch (e, st) {
      AppLogger.warning('Supabase getGuestFeedbacks fallback: $e', error: e, stackTrace: st);
      return const Right([]);
    }
  }

  Future<Either<Failure, GuestFeedback>> saveGuestFeedback(GuestFeedback feedback) async {
    try {
      final parsedOrderId = int.tryParse(feedback.orderId.replaceAll(RegExp(r'[^0-9]'), ''));

      final payload = {
        'id': feedback.id,
        'restaurant_id': SupabaseConfig.defaultRestaurantId,
        'customer_name': feedback.customerName,
        'customer_phone': feedback.customerPhone,
        'order_id': parsedOrderId,
        'overall_rating': feedback.overallRating,
        'food_quality_rating': feedback.foodQualityRating,
        'service_speed_rating': feedback.serviceSpeedRating,
        'cleanliness_rating': feedback.cleanlinessRating,
        'comment': feedback.comment,
        'is_resolved': feedback.isResolved,
        'resolution_notes': feedback.resolutionNotes,
        'compensation_coupon_code': feedback.compensationCouponCode,
        'created_at': feedback.createdAt.toIso8601String(),
      };

      await _supabase.from(SupabaseConfig.guestFeedbacksTable).upsert(payload);
      return Right(feedback);
    } catch (e, st) {
      AppLogger.error('Supabase saveGuestFeedback failed: $e', error: e, stackTrace: st);
      return Left(ServerFailure('فشل حفظ تقييم العميل: $e'));
    }
  }
}
