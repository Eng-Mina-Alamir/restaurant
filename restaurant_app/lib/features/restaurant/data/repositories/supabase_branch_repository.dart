import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/supabase_config.dart';
import '../../../../core/data/local_cache_service.dart';
import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/branch_entity.dart';

/// Supabase-backed repository for restaurant branches and chain data.
class SupabaseBranchRepository {
  SupabaseBranchRepository({
    required SupabaseClient supabase,
    LocalCacheService? cache,
  })  : _supabase = supabase,
        _cache = cache;

  final SupabaseClient _supabase;
  final LocalCacheService? _cache;

  static const String _cacheKey = 'branches_v1';

  Future<Either<Failure, List<BranchEntity>>> getBranches() async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.restaurantsTable)
          .select()
          .order('name');

      final list = (response as List).map((row) {
        final map = Map<String, dynamic>.from(row as Map);
        return BranchEntity(
          id: map['id']?.toString() ?? '',
          name: map['name'] as String? ?? 'فرع المطعم',
          city: 'القاهرة',
          address: map['address'] as String? ?? '',
          phone: map['phone'] as String? ?? '',
          managerName: 'مدير الفرع',
          isOpen: true,
          totalTables: (map['total_tables'] as num?)?.toInt() ?? 20,
          activeOrdersCount: 0,
          todaySales: 0.0,
          totalOrdersToday: 0,
          rating: 4.8,
          colorValue: 0xFFC2410C,
        );
      }).toList();

      if (list.isNotEmpty && _cache != null) {
        await _cache.writeList(
          _cacheKey,
          list.map((b) => {
            'id': b.id,
            'name': b.name,
            'city': b.city,
            'address': b.address,
            'phone': b.phone,
            'managerName': b.managerName,
            'isOpen': b.isOpen,
            'totalTables': b.totalTables,
            'activeOrdersCount': b.activeOrdersCount,
            'todaySales': b.todaySales,
            'totalOrdersToday': b.totalOrdersToday,
            'rating': b.rating,
            'colorValue': b.colorValue,
          }).toList(),
        );
      }

      return Right(list);
    } catch (e, st) {
      AppLogger.warning('Supabase getBranches fallback: $e', error: e, stackTrace: st);
      final cache = _cache;
      if (cache != null) {
        final cached = cache.readList(_cacheKey);
        if (cached.isNotEmpty) {
          final list = cached.map((map) {
            return BranchEntity(
              id: map['id']?.toString() ?? '',
              name: map['name'] as String? ?? '',
              city: map['city'] as String? ?? '',
              address: map['address'] as String? ?? '',
              phone: map['phone'] as String? ?? '',
              managerName: map['managerName'] as String? ?? '',
              isOpen: map['isOpen'] as bool? ?? true,
              totalTables: (map['totalTables'] as num?)?.toInt() ?? 0,
              activeOrdersCount: (map['activeOrdersCount'] as num?)?.toInt() ?? 0,
              todaySales: (map['todaySales'] as num?)?.toDouble() ?? 0.0,
              totalOrdersToday: (map['totalOrdersToday'] as num?)?.toInt() ?? 0,
              rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
              colorValue: (map['colorValue'] as num?)?.toInt() ?? 0xFFC2410C,
            );
          }).toList();
          return Right(list);
        }
      }
      return const Right([]);
    }
  }
}
