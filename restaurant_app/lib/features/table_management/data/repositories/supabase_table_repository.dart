import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/supabase_config.dart';
import '../../../../core/data/local_cache_service.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/restaurant_table.dart';
import '../../domain/repositories/table_repository.dart';

/// Supabase-backed [TableRepository].
///
/// Single source of truth is Supabase. Empty table => empty list (truthful),
/// failure with no Supabase-loaded session data => [Left] (error + retry).
/// The Hive mirror holds only previously fetched Supabase rows (stale-safe),
/// never seed data.
class SupabaseTableRepository implements TableRepository {
  SupabaseTableRepository(this._supabase, [this._cache]);

  final SupabaseClient _supabase;
  final LocalCacheService? _cache;
  List<RestaurantTable>? _cachedTables;

  static const String _cacheKey = 'cached_tables';

  void _ensureCache() {
    _cachedTables ??= _loadFromPersistentCache() ?? <RestaurantTable>[];
  }

  List<RestaurantTable>? _loadFromPersistentCache() {
    final cache = _cache;
    if (cache == null) return null;
    try {
      final list = cache.readList(_cacheKey);
      if (list.isEmpty) return null;
      return list.map(RestaurantTable.fromJson).toList();
    } catch (e) {
      AppLogger.warning('Failed to read tables from local cache: $e');
      return null;
    }
  }

  Future<void> _persistCache() async {
    final cache = _cache;
    final tables = _cachedTables;
    if (cache != null && tables != null) {
      try {
        await cache.writeList(_cacheKey, tables.map((t) => t.toJson()).toList());
      } catch (_) {}
    }
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
            tableNumber: (map['table_number'] is num)
                ? (map['table_number'] as num).toInt()
                : (int.tryParse(map['table_number']?.toString() ?? '') ?? 1),
            capacity: (map['capacity'] is num)
                ? (map['capacity'] as num).toInt()
                : (int.tryParse(map['capacity']?.toString() ?? '') ?? 4),
            location: map['location']?.toString() ?? 'صالة',
            status: TableStatus.fromName(map['status']?.toString()),
            currentOrderId: map['current_order_id']?.toString(),
            assignedWaiterId: map['assigned_waiter_id']?.toString(),
            lastUpdated: map['last_updated'] != null
                ? DateTime.tryParse(map['last_updated'].toString())
                : null,
          ),
        );
      }

      if (tables.isEmpty) {
        _cachedTables = tables;
        return Right<Failure, List<RestaurantTable>>(tables);
      }

      _cachedTables = tables;
      await _persistCache();
      return Right<Failure, List<RestaurantTable>>(tables);
    } catch (e) {
      AppLogger.warning('Supabase getTables failed: $e');
      final fallback = _loadFromPersistentCache();
      if (fallback != null && fallback.isNotEmpty) {
        _cachedTables = fallback;
        return Right<Failure, List<RestaurantTable>>(fallback);
      }
      return Left<Failure, List<RestaurantTable>>(
        ServerFailure('فشل تحميل الطاولات من Supabase: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, RestaurantTable>> updateTable(
    RestaurantTable table,
  ) async {
    _ensureCache();
    try {
      final updateData = <String, dynamic>{
        'table_number': table.tableNumber,
        'capacity': table.capacity,
        'location': table.location,
        'status': table.status.name,
        'current_order_id': table.currentOrderId != null
            ? (int.tryParse(table.currentOrderId!) ?? table.currentOrderId)
            : null,
        'assigned_waiter_id': table.assignedWaiterId,
        'last_updated': DateTime.now().toIso8601String(),
      };

      final parsedId = int.tryParse(table.id);
      if (parsedId != null) {
        await _supabase
            .from(SupabaseConfig.tablesTable)
            .update(updateData)
            .eq('id', parsedId);
      } else {
        await _supabase
            .from(SupabaseConfig.tablesTable)
            .update(updateData)
            .eq('id', table.id);
      }

      final index = _cachedTables!.indexWhere((t) => t.id == table.id);
      if (index != -1) {
        _cachedTables![index] = table;
      }
      await _persistCache();
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
      final insertData = <String, dynamic>{
        'table_number': table.tableNumber,
        'capacity': table.capacity,
        'location': table.location,
        'status': table.status.name,
        'current_order_id': table.currentOrderId != null
            ? (int.tryParse(table.currentOrderId!) ?? table.currentOrderId)
            : null,
        'assigned_waiter_id': table.assignedWaiterId,
        'last_updated': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from(SupabaseConfig.tablesTable)
          .insert(insertData)
          .select('id')
          .single();

      final generatedId = response['id']?.toString() ?? table.id;
      final savedTable = table.copyWith(id: generatedId);

      _cachedTables!.add(savedTable);
      await _persistCache();
      return Right<Failure, RestaurantTable>(savedTable);
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
      final parsedId = int.tryParse(id);
      if (parsedId != null) {
        await _supabase
            .from(SupabaseConfig.tablesTable)
            .delete()
            .eq('id', parsedId);
      } else {
        await _supabase
            .from(SupabaseConfig.tablesTable)
            .delete()
            .eq('id', id);
      }

      _cachedTables!.removeWhere((t) => t.id == id);
      await _persistCache();
      return const Right<Failure, void>(null);
    } catch (e) {
      AppLogger.error('Supabase deleteTable error: $e');
      return Left<Failure, void>(
        ServerFailure('فشل حذف الطاولة: $e'),
      );
    }
  }
}
