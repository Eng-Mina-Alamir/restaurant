import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/supabase_config.dart';
import '../../../../core/data/local_cache_service.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/restaurant_table.dart';
import '../../domain/repositories/table_repository.dart';

/// Supabase-backed [TableRepository] with Hive cache-aside persistence.
class SupabaseTableRepository implements TableRepository {
  SupabaseTableRepository(this._supabase, [this._cache]);

  final SupabaseClient _supabase;
  final LocalCacheService? _cache;
  List<RestaurantTable>? _cachedTables;

  static const String _tablesCacheKey = 'tables_v1';

  void _ensureCache() {
    _cachedTables ??= [];
  }

  @override
  Future<Either<Failure, List<RestaurantTable>>> getTables() async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.tablesTable)
          .select()
          .order('table_number', ascending: true);

      final List<RestaurantTable> tables = [];
      for (final raw in (response as List)) {
        final map = Map<String, dynamic>.from(raw as Map);
        tables.add(
          RestaurantTable(
            id: map['id']?.toString() ?? '',
            tableNumber: (map['table_number'] as num?)?.toInt() ?? 1,
            capacity: (map['capacity'] as num?)?.toInt() ?? 4,
            location: map['location'] as String? ?? 'صالة',
            status: TableStatus.fromName(map['status'] as String?),
            currentOrderId: map['current_order_id']?.toString(),
            assignedWaiterId: map['assigned_waiter_id'] as String?,
            lastUpdated: map['last_updated'] != null
                ? DateTime.tryParse(map['last_updated'] as String)
                : null,
          ),
        );
      }

      _cachedTables = tables;

      final cache = _cache;
      if (cache != null) {
        await cache.writeList(
          _tablesCacheKey,
          tables.map((t) => {
            'id': t.id,
            'tableNumber': t.tableNumber,
            'capacity': t.capacity,
            'location': t.location,
            'status': t.status.name,
            'currentOrderId': t.currentOrderId,
            'assignedWaiterId': t.assignedWaiterId,
            'lastUpdated': t.lastUpdated?.toIso8601String(),
          }).toList(),
        );
      }

      return Right<Failure, List<RestaurantTable>>(tables);
    } catch (e, st) {
      AppLogger.warning('Supabase getTables failed: $e, reading from local cache', error: e, stackTrace: st);
      final cache = _cache;
      if (cache != null) {
        final cached = cache.readList(_tablesCacheKey);
        if (cached.isNotEmpty) {
          final tables = cached.map((map) => RestaurantTable(
            id: map['id']?.toString() ?? '',
            tableNumber: (map['tableNumber'] as num?)?.toInt() ?? 1,
            capacity: (map['capacity'] as num?)?.toInt() ?? 4,
            location: map['location'] as String? ?? 'صالة',
            status: TableStatus.fromName(map['status'] as String?),
            currentOrderId: map['currentOrderId'] as String?,
            assignedWaiterId: map['assignedWaiterId'] as String?,
            lastUpdated: map['lastUpdated'] != null
                ? DateTime.tryParse(map['lastUpdated'] as String)
                : null,
          )).toList();
          _cachedTables = tables;
          return Right<Failure, List<RestaurantTable>>(tables);
        }
      }

      final empty = _cachedTables ?? <RestaurantTable>[];
      return Right<Failure, List<RestaurantTable>>(empty);
    }
  }

  @override
  Future<Either<Failure, RestaurantTable>> updateTable(
    RestaurantTable table,
  ) async {
    _ensureCache();
    try {
      final parsedId = int.tryParse(table.id) ?? table.id;
      final parsedOrderId = table.currentOrderId != null
          ? int.tryParse(table.currentOrderId!.replaceAll(RegExp(r'[^0-9]'), ''))
          : null;

      await _supabase
          .from(SupabaseConfig.tablesTable)
          .update({
            'table_number': table.tableNumber,
            'capacity': table.capacity,
            'location': table.location,
            'status': table.status.name,
            'current_order_id': parsedOrderId,
            'assigned_waiter_id': table.assignedWaiterId,
            'last_updated': DateTime.now().toIso8601String(),
          })
          .eq('id', parsedId);

      final index = _cachedTables!.indexWhere((t) => t.id == table.id);
      if (index != -1) {
        _cachedTables![index] = table;
      }

      return Right<Failure, RestaurantTable>(table);
    } catch (e) {
      AppLogger.error('Supabase updateTable error: $e');
      return Left<Failure, RestaurantTable>(
        ServerFailure('فشل تحديث الطاولة: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, RestaurantTable>> addTable(
    RestaurantTable table,
  ) async {
    _ensureCache();
    try {
      final response = await _supabase.from(SupabaseConfig.tablesTable).insert({
        'table_number': table.tableNumber,
        'capacity': table.capacity,
        'location': table.location,
        'status': table.status.name,
        'current_order_id': table.currentOrderId != null
            ? int.tryParse(table.currentOrderId!.replaceAll(RegExp(r'[^0-9]'), ''))
            : null,
        'assigned_waiter_id': table.assignedWaiterId,
        'last_updated': DateTime.now().toIso8601String(),
        'restaurant_id': SupabaseConfig.defaultRestaurantId,
      }).select().single();

      final created = table.copyWith(
        id: response['id']?.toString() ?? table.id,
      );

      _cachedTables!.add(created);
      return Right<Failure, RestaurantTable>(created);
    } catch (e) {
      AppLogger.error('Supabase addTable error: $e');
      return Left<Failure, RestaurantTable>(
        ServerFailure('فشل إضافة الطاولة: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> deleteTable(String id) async {
    _ensureCache();
    try {
      final parsedId = int.tryParse(id) ?? id;
      await _supabase.from(SupabaseConfig.tablesTable).delete().eq('id', parsedId);

      _cachedTables!.removeWhere((t) => t.id == id);
      return const Right<Failure, void>(null);
    } catch (e) {
      AppLogger.error('Supabase deleteTable error: $e');
      return Left<Failure, void>(
        ServerFailure('فشل حذف الطاولة: $e'),
      );
    }
  }
}
