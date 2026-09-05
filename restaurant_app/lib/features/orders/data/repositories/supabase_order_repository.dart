import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/supabase_config.dart';
import '../../../../core/data/local_cache_service.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/entities/order_item.dart';
import '../../domain/entities/order_status_log_entry.dart';
import '../../domain/repositories/order_repository.dart';

/// Supabase-backed [OrderRepository] with offline local cache fallback and real-time support.
class SupabaseOrderRepository implements OrderRepository {
  SupabaseOrderRepository({
    required SupabaseClient supabase,
    LocalCacheService? cache,
  }) : _supabase = supabase,
       _cache = cache;

  final SupabaseClient _supabase;
  final LocalCacheService? _cache;
  static const String _cacheKey = 'orders_v1';

  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static String? _sanitizeUuid(String? input, {String? defaultFallback}) {
    if (input == null || input.isEmpty) return defaultFallback;
    if (_uuidRegex.hasMatch(input)) return input;
    return defaultFallback;
  }

  static const String defaultRestaurantId =
      SupabaseConfig.defaultRestaurantId;

  @override
  Future<Either<Failure, OrderEntity>> createOrder(OrderEntity order) async {
    try {
      final numericId = int.tryParse(order.id);
      final tableNum = order.tableId != null && order.tableId!.trim().isNotEmpty
          ? int.tryParse(order.tableId!.trim())
          : null;

      // Server is the sole generator of order_number (trg_set_order_number):
      // temp/local ids (non-numeric ORD-*/local-*) are sent as NULL so the
      // trigger mints a unique ORD-YYMMDD-XXXX. Only already-numeric ids
      // (retry of a persisted order) echo their order_number.
      final orderRow = <String, dynamic>{
        'id': ?numericId,
        'order_number': numericId != null ? order.id : null,
        'restaurant_id': _sanitizeUuid(
          order.restaurantId,
          defaultFallback: defaultRestaurantId,
        ),
        'customer_id': _sanitizeUuid(order.customerId),
        'table_id': ?tableNum,
        'waiter_id': _sanitizeUuid(order.waiterId),
        'assigned_kitchen_id': _sanitizeUuid(order.assignedKitchenId),
        'driver_id': _sanitizeUuid(order.driverId),
        'order_type': order.orderType.name,
        'status': order.status.name,
        'subtotal': order.subtotal,
        'tax_amount': order.taxAmount,
        'discount_amount': order.discountAmount,
        'total_amount': order.totalAmount,
        'payment_method': order.paymentMethod?.name,
        'delivery_address': order.deliveryAddress,
        'delivery_notes': order.deliveryNotes,
        'created_at': order.createdAt.toIso8601String(),
        'items_json': order.items.map((i) => i.toJson()).toList(),
      };

      Map<String, dynamic>? insertedRow;
      try {
        if (numericId != null) {
          final res = await _supabase
              .from(SupabaseConfig.ordersTable)
              .upsert(orderRow)
              .select()
              .single();
          insertedRow = Map<String, dynamic>.from(res as Map);
        } else {
          final res = await _supabase
              .from(SupabaseConfig.ordersTable)
              .insert(orderRow)
              .select()
              .single();
          insertedRow = Map<String, dynamic>.from(res as Map);
        }
      } catch (e) {
        if (e.toString().contains('items_json') ||
            e.toString().contains('restaurant_id')) {
          final rowCleaned = Map<String, dynamic>.from(orderRow)
            ..remove('items_json')
            ..remove('restaurant_id');
          if (numericId != null) {
            final res = await _supabase
                .from(SupabaseConfig.ordersTable)
                .upsert(rowCleaned)
                .select()
                .single();
            insertedRow = Map<String, dynamic>.from(res as Map);
          } else {
            final res = await _supabase
                .from(SupabaseConfig.ordersTable)
                .insert(rowCleaned)
                .select()
                .single();
            insertedRow = Map<String, dynamic>.from(res as Map);
          }
        } else {
          rethrow;
        }
      }

      final persistedOrder = _orderFromRow(insertedRow);
      final effectiveOrderId = int.tryParse(persistedOrder.id) ?? numericId;

      // 2. Also insert line items into `order_items` table (delete-then-insert to prevent duplicates)
      if (effectiveOrderId != null) {
        try {
          final itemsPayload = order.items
              .map(
                (item) => <String, dynamic>{
                  'order_id': effectiveOrderId,
                  'menu_item_id': int.tryParse(item.menuItem.id) ?? 1,
                  'item_name': item.menuItem.name,
                  'price': item.menuItem.price,
                  'quantity': item.quantity,
                  'total_price': item.lineTotal,
                  'special_notes': item.specialNotes,
                  'modifiers_json': item.selectedModifiers
                      .map((m) => m.toJson())
                      .toList(),
                  'created_at': item.addedAt.toIso8601String(),
                },
              )
              .toList();

          if (itemsPayload.isNotEmpty) {
            try {
              await _supabase
                  .from(SupabaseConfig.orderItemsTable)
                  .delete()
                  .eq('order_id', effectiveOrderId);
            } catch (e) {
              AppLogger.warning(
                'Could not delete old order_items for $effectiveOrderId: $e',
              );
            }

            await _supabase
                .from(SupabaseConfig.orderItemsTable)
                .upsert(itemsPayload);
          }
        } catch (e) {
          AppLogger.warning('Could not insert items into order_items table: $e');
        }
      }

      // 3. Cache locally
      await _cacheOrderLocally(persistedOrder);

      return Right<Failure, OrderEntity>(persistedOrder);
    } catch (e) {
      AppLogger.error('Supabase createOrder error: $e');
      // Save locally so orders aren't lost
      await _cacheOrderLocally(order);
      return Left<Failure, OrderEntity>(
        ServerFailure('فشل حفظ الطلب في السيرفر: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, List<OrderEntity>>> getOrders() async {
    try {
      // Limit to last 90 days and cap at 200 rows to stay within free-plan
      // bandwidth. Older orders can be fetched on-demand via getOrderById.
      final cutoff = DateTime.now()
          .subtract(const Duration(days: 90))
          .toIso8601String();
      final response = await _supabase
          .from(SupabaseConfig.ordersTable)
          .select()
          .eq('is_archived', false)
          .gte('created_at', cutoff)
          .order('created_at', ascending: false)
          .limit(200);

      final List<OrderEntity> orders = [];
      for (final raw in (response as List)) {
        final map = Map<String, dynamic>.from(raw as Map);
        orders.add(_orderFromRow(map));
      }

      final cache = _cache;
      if (orders.isNotEmpty && cache != null) {
        await cache.writeList(
          _cacheKey,
          orders.map((o) => o.toJson()).toList(),
        );
      }

      return Right<Failure, List<OrderEntity>>(orders);
    } catch (e) {
      AppLogger.warning('Supabase getOrders failed: $e');
      return Left<Failure, List<OrderEntity>>(
        ServerFailure('فشل تحميل الطلبات من Supabase: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, OrderEntity?>> getOrderById(String orderId) async {
    try {
      final numericId = int.tryParse(orderId);
      final dynamic response = numericId != null
          ? await _supabase
              .from(SupabaseConfig.ordersTable)
              .select()
              .eq('id', numericId)
              .limit(1)
          : await _supabase
              .from(SupabaseConfig.ordersTable)
              .select()
              .eq('order_number', orderId)
              .limit(1);
      final rows = response as List;
      if (rows.isEmpty) {
        return const Right<Failure, OrderEntity?>(null);
      }
      return Right<Failure, OrderEntity?>(
        _orderFromRow(Map<String, dynamic>.from(rows.first as Map)),
      );
    } catch (e) {
      AppLogger.error('Supabase getOrderById error: $e (orderId=$orderId)');
      return Left<Failure, OrderEntity?>(
        ServerFailure('فشل جلب الطلب: $e'),
      );
    }
  }

  /// Maps a raw `orders` row (including `items_json`) into an [OrderEntity].
  ///
  /// Shared by [getOrders], realtime event handlers, and claim/revert flows.
  static OrderEntity _orderFromRow(Map<String, dynamic> map) {
    List<OrderItem> items = [];
    final itemsSource = map['items_json'] ?? map['items'];
    if (itemsSource is List) {
      for (final raw in itemsSource) {
        if (raw is Map) {
          try {
            items.add(OrderItem.fromJson(Map<String, dynamic>.from(raw)));
          } catch (_) {}
        }
      }
    }

    final rawCreatedAt = map['created_at'] ?? map['createdAt'];
    final rawCompletedAt = map['completed_at'] ?? map['completedAt'];

    return OrderEntity(
      id: map['id']?.toString() ?? '',
      restaurantId: (map['restaurant_id'] ?? map['restaurantId'])?.toString() ?? defaultRestaurantId,
      customerId: (map['customer_id'] ?? map['customerId'])?.toString(),
      tableId: (map['table_id'] ?? map['tableId'])?.toString(),
      waiterId: (map['waiter_id'] ?? map['waiterId'])?.toString(),
      assignedKitchenId: (map['assigned_kitchen_id'] ?? map['assignedKitchenId'])?.toString(),
      driverId: (map['driver_id'] ?? map['driverId'])?.toString(),
      orderType: OrderType.fromName((map['order_type'] ?? map['orderType'])?.toString()),
      items: items,
      status: OrderStatus.fromName(map['status']?.toString()),
      subtotal: ((map['subtotal'] ?? map['subTotal']) as num?)?.toDouble() ?? 0.0,
      taxAmount: ((map['tax_amount'] ?? map['taxAmount']) as num?)?.toDouble() ?? 0.0,
      discountAmount: ((map['discount_amount'] ?? map['discountAmount']) as num?)?.toDouble() ?? 0.0,
      totalAmount: ((map['total_amount'] ?? map['totalAmount']) as num?)?.toDouble() ?? 0.0,
      paymentMethod: (map['payment_method'] ?? map['paymentMethod']) != null
          ? PaymentMethod.fromName((map['payment_method'] ?? map['paymentMethod']).toString())
          : null,
      deliveryAddress: (map['delivery_address'] ?? map['deliveryAddress'])?.toString(),
      deliveryNotes: (map['delivery_notes'] ?? map['deliveryNotes'])?.toString(),
      createdAt: rawCreatedAt != null
          ? DateTime.tryParse(rawCreatedAt.toString()) ?? DateTime.now()
          : DateTime.now(),
      completedAt: rawCompletedAt != null
          ? DateTime.tryParse(rawCompletedAt.toString())
          : null,
      estimatedMinutes: ((map['estimated_minutes'] ?? map['estimatedMinutes']) as num?)?.toInt(),
    );
  }

  /// Exposed parser for realtime event listeners
  static OrderEntity fromRow(Map<String, dynamic> map) => _orderFromRow(map);

  @override
  Future<Either<Failure, OrderEntity>> claimOrder(
    String orderId,
    String kitchenUserId,
  ) async {
    try {
      final numericId = int.tryParse(orderId);
      final query = _supabase
          .from(SupabaseConfig.ordersTable)
          .update({'assigned_kitchen_id': kitchenUserId});
      final dynamic response = numericId != null
          ? await query.eq('id', numericId).select().single()
          : await query.eq('order_number', orderId).select().single();

      final claimed = _orderFromRow(Map<String, dynamic>.from(response as Map));
      await _cacheOrderLocally(claimed);
      return Right<Failure, OrderEntity>(claimed);
    } catch (e) {
      AppLogger.error('Supabase claimOrder error: $e');
      return Left<Failure, OrderEntity>(ServerFailure('فشل استلام الطلب: $e'));
    }
  }

  @override
  Future<Either<Failure, OrderEntity>> revertStatus(
    String orderId,
    OrderStatus toStatus, {
    required String actorId,
    String? reason,
  }) async {
    try {
      final numericId = int.tryParse(orderId);
      final query = _supabase.from(SupabaseConfig.ordersTable).select();
      final dynamic rows = numericId != null
          ? await query.eq('id', numericId).limit(1)
          : await query.eq('order_number', orderId).limit(1);

      if ((rows as List).isEmpty) {
        return const Left<Failure, OrderEntity>(
          NotFoundFailure('الطلب غير موجود'),
        );
      }
      final current = _orderFromRow(
        Map<String, dynamic>.from(rows.first as Map),
      );
      final resolvedNumericId = int.tryParse(current.id) ?? numericId;

      // 2. Guarded transition: only legal single-step backward moves.
      if (!current.status.canRevertTo(toStatus)) {
        return Left<Failure, OrderEntity>(
          ValidationFailure('لا يمكن التراجع من ${current.status.labelAr}'),
        );
      }

      // 2b. Business rule: at most TWO reverts per order (التراجع مرتان كحد أقصى)
      if (resolvedNumericId != null) {
        final revertLog = await _supabase
            .from(SupabaseConfig.orderStatusLogTable)
            .select('id')
            .eq('order_id', resolvedNumericId)
            .eq('is_revert', true);
        if ((revertLog as List).length >= 2) {
          return const Left<Failure, OrderEntity>(
            ValidationFailure(
              'تم تجاوز الحد المسموح للتراجع عن هذا الطلب (مرتان كحد أقصى)',
            ),
          );
        }
      }

      // 3. Persist the new status.
      final updateQuery = _supabase
          .from(SupabaseConfig.ordersTable)
          .update({'status': toStatus.name});
      final dynamic response = resolvedNumericId != null
          ? await updateQuery.eq('id', resolvedNumericId).select().single()
          : await updateQuery.eq('order_number', orderId).select().single();

      final updated = _orderFromRow(Map<String, dynamic>.from(response as Map));

      // 4. Audit trail is written EXCLUSIVELY by the DB trigger
      // trg_log_order_status_change (single writer — previously this method
      // also inserted manually, producing duplicate is_revert rows). The
      // reason/actor for reverts is recorded via the trigger's changed_by
      // (auth.uid()); max-2-reverts is enforced DB-side in
      // validate_order_status_transition().

      await _cacheOrderLocally(updated);
      return Right<Failure, OrderEntity>(updated);
    } catch (e) {
      AppLogger.error('Supabase revertStatus error: $e');
      return Left<Failure, OrderEntity>(
        ServerFailure('فشل التراجع عن حالة الطلب: $e'),
      );
    }
  }

  /// Updates status of an order in Supabase with server-side validation.
  @override
  Future<Either<Failure, void>> updateOrderStatus(
    String orderId,
    OrderStatus status,
  ) async {
    try {
      final numericId = int.tryParse(orderId);
      final updateData = <String, dynamic>{
        'status': status.name,
        if (status == OrderStatus.completed || status == OrderStatus.served)
          'completed_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (numericId != null) {
        await _supabase
            .from(SupabaseConfig.ordersTable)
            .update(updateData)
            .eq('id', numericId);
      } else {
        await _supabase
            .from(SupabaseConfig.ordersTable)
            .update(updateData)
            .eq('order_number', orderId);
      }
      return const Right<Failure, void>(null);
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('Invalid status transition') ||
          msg.contains('Cannot change status')) {
        AppLogger.warning(
          'updateOrderStatus: transition rejected by DB for $orderId: $msg',
        );
        return Left<Failure, void>(
          ValidationFailure('تحويل الحالة غير مسموح: $msg'),
        );
      }
      return Left<Failure, void>(ServerFailure('فشل تحديث حالة الطلب: $e'));
    }
  }

  /// Persists [items] to the `order_items` table for an existing order.
  Future<Either<Failure, void>> persistOrderItems(
    String orderId,
    List<OrderItem> items,
  ) async {
    try {
      final numericId = int.tryParse(orderId);
      final payload = items
          .map(
            (item) => <String, dynamic>{
              'order_id': ?numericId,
              'menu_item_id': int.tryParse(item.menuItem.id) ?? 1,
              'item_name': item.menuItem.name,
              'price': item.menuItem.price,
              'quantity': item.quantity,
              'total_price': item.lineTotal,
              'special_notes': item.specialNotes,
              'modifiers_json': item.selectedModifiers
                  .map((m) => m.toJson())
                  .toList(),
              'created_at': item.addedAt.toIso8601String(),
            },
          )
          .toList();
      if (payload.isEmpty) return const Right<Failure, void>(null);
      await _supabase
          .from(SupabaseConfig.orderItemsTable)
          .insert(payload);

      return const Right<Failure, void>(null);
    } catch (e) {
      AppLogger.error('persistOrderItems error: $e');
      return Left<Failure, void>(
        ServerFailure('فشل حفظ العناصر المضافة: $e'),
      );
    }
  }

  /// Updates the driver_id on the order row in Supabase.
  Future<Either<Failure, void>> updateOrderDriverId(
    String orderId,
    String driverId,
  ) async {
    try {
      final numericId = int.tryParse(orderId);
      final sanitizedId = _sanitizeUuid(driverId);
      if (numericId != null) {
        await _supabase
            .from(SupabaseConfig.ordersTable)
            .update({'driver_id': sanitizedId})
            .eq('id', numericId);
      } else {
        await _supabase
            .from(SupabaseConfig.ordersTable)
            .update({'driver_id': sanitizedId})
            .eq('order_number', orderId);
      }
      return const Right<Failure, void>(null);
    } catch (e) {
      AppLogger.error('updateOrderDriverId error: $e');
      return Left<Failure, void>(
        ServerFailure('فشل ربط السائق بالطلب: $e'),
      );
    }
  }

  /// Updates the table_id on the order row in Supabase.
  Future<Either<Failure, void>> updateOrderTableId(
    String orderId,
    String tableId,
  ) async {
    try {
      final numericId = int.tryParse(orderId);
      if (numericId != null) {
        await _supabase
            .from(SupabaseConfig.ordersTable)
            .update({'table_id': tableId})
            .eq('id', numericId);
      } else {
        await _supabase
            .from(SupabaseConfig.ordersTable)
            .update({'table_id': tableId})
            .eq('order_number', orderId);
      }
      return const Right<Failure, void>(null);
    } catch (e) {
      AppLogger.error('updateOrderTableId error: $e');
      return Left<Failure, void>(
        ServerFailure('فشل تحديث الطاولة للطلب: $e'),
      );
    }
  }

  /// Resolves any order identifier (numeric id string OR order_number text
  /// like `ORD-260904-0018`) to the numeric `orders.id` used by bigint FK
  /// columns (`order_status_log`, `delivery_assignments`, `payments`).
  /// Returns null when the order is not yet persisted (temp local id).
  /// Transport errors propagate to the caller (which maps them to Left).
  Future<int?> resolveNumericOrderId(String orderId) async {
    final direct = int.tryParse(orderId);
    if (direct != null) return direct;
    final rows = await _supabase
        .from(SupabaseConfig.ordersTable)
        .select('id')
        .eq('order_number', orderId)
        .limit(1);
    final list = rows as List;
    if (list.isEmpty) return null;
    return int.tryParse(
      (list.first as Map)['id']?.toString() ?? '',
    );
  }

  @override
  Future<Either<Failure, List<OrderStatusLogEntry>>> getAuditTrail(
    String orderId,
  ) async {
    try {
      // Numeric ids hit the log table directly (a transport failure stays a
      // Left, preserving the offline-failure contract). Text ids
      // (order_number / temp local ids) resolve first: unknown -> empty
      // trail, resolution transport failure -> Left.
      int? numericId = int.tryParse(orderId);
      if (numericId == null) {
        try {
          numericId = await resolveNumericOrderId(orderId);
        } catch (e) {
          return Left<Failure, List<OrderStatusLogEntry>>(
            ServerFailure('فشل تحميل سجل الحالة: $e'),
          );
        }
        if (numericId == null) {
          return const Right<Failure, List<OrderStatusLogEntry>>([]);
        }
      }
      final response = await _supabase
          .from(SupabaseConfig.orderStatusLogTable)
          .select()
          .eq('order_id', numericId)
          .order('created_at');
      final trail = (response as List)
          .map((raw) => _logFromRow(Map<String, dynamic>.from(raw as Map)))
          .toList();
      return Right<Failure, List<OrderStatusLogEntry>>(trail);
    } catch (e) {
      AppLogger.error('Supabase getAuditTrail error: $e');
      return Left<Failure, List<OrderStatusLogEntry>>(
        ServerFailure('فشل تحميل سجل الحالة: $e'),
      );
    }
  }

  /// Maps a raw `order_status_log` row (snake_case columns) into an
  /// [OrderStatusLogEntry].
  static OrderStatusLogEntry _logFromRow(Map<String, dynamic> map) {
    return OrderStatusLogEntry(
      orderId: map['order_id']?.toString() ?? '',
      fromStatus: OrderStatus.fromName(map['from_status'] as String?),
      toStatus: OrderStatus.fromName(map['to_status'] as String?),
      actorId: map['changed_by']?.toString() ?? '',
      reason: map['reason'] as String?,
      isRevert: map['is_revert'] as bool? ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Future<void> _cacheOrderLocally(OrderEntity order) async {
    final cache = _cache;
    if (cache == null) return;
    try {
      final all = _loadFromCache();
      final index = all.indexWhere((o) => o.id == order.id);
      if (index == -1) {
        all.add(order);
      } else {
        all[index] = order;
      }
      await cache.writeList(_cacheKey, all.map((o) => o.toJson()).toList());
    } catch (e) {
      AppLogger.warning(
        '_cacheOrderLocally: failed to write cache for ${order.id}: $e',
      );
    }
  }

  List<OrderEntity> _loadFromCache() {
    final cache = _cache;
    if (cache == null) return [];
    try {
      return cache.readList(_cacheKey).map(OrderEntity.fromJson).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } catch (_) {
      return [];
    }
  }

  /// Read-only mirror of persisted orders for staff continuity during offline periods.
  List<OrderEntity> getStaffOfflineOrdersMirror() => _loadFromCache();
}
