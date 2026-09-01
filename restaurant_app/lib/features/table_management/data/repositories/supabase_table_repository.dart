import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/supabase_config.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/restaurant_table.dart';
import '../../domain/repositories/table_repository.dart';
import '../table_seed_data.dart';

/// Supabase-backed [TableRepository] with fallback to seed data.
class SupabaseTableRepository implements TableRepository {
  SupabaseTableRepository(this._supabase);

  final SupabaseClient _supabase;
  List<RestaurantTable>? _cachedTables;

  void _ensureCache() {
    _cachedTables ??= TableSeedData.buildTables();
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
            currentOrderId: map['current_order_id'] as String?,
            assignedWaiterId: map['assigned_waiter_id'] as String?,
            lastUpdated: map['last_updated'] != null
                ? DateTime.tryParse(map['last_updated'] as String)
                : null,
          ),
        );
      }

      if (tables.isEmpty) {
        final fallback = TableSeedData.buildTables();
        _cachedTables = fallback;
        return Right<Failure, List<RestaurantTable>>(fallback);
      }

      _cachedTables = tables;
      return Right<Failure, List<RestaurantTable>>(tables);
    } catch (e) {
      AppLogger.warning('Supabase getTables failed: $e, using seed tables');
      final fallback = _cachedTables ?? TableSeedData.buildTables();
      _cachedTables = fallback;
      return Right<Failure, List<RestaurantTable>>(fallback);
    }
  }

  @override
  Future<Either<Failure, RestaurantTable>> updateTable(
    RestaurantTable table,
  ) async {
    _ensureCache();
    try {
      await _supabase
          .from(SupabaseConfig.tablesTable)
          .update({
            'table_number': table.tableNumber,
            'capacity': table.capacity,
            'location': table.location,
            'status': table.status.name,
            'current_order_id': table.currentOrderId,
            'assigned_waiter_id': table.assignedWaiterId,
            'last_updated': DateTime.now().toIso8601String(),
          })
          .eq('id', table.id);

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
      await _supabase.from(SupabaseConfig.tablesTable).insert({
        'id': table.id,
        'table_number': table.tableNumber,
        'capacity': table.capacity,
        'location': table.location,
        'status': table.status.name,
        'current_order_id': table.currentOrderId,
        'assigned_waiter_id': table.assignedWaiterId,
        'last_updated': DateTime.now().toIso8601String(),
      });

      _cachedTables!.add(table);
      return Right<Failure, RestaurantTable>(table);
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
      await _supabase.from(SupabaseConfig.tablesTable).delete().eq('id', id);

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
