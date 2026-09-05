import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/supabase_providers.dart';
import '../../../../core/tenant/tenant_context.dart';
import '../../data/repositories/supabase_restaurant_repository.dart';
import '../../domain/entities/restaurant_entity.dart';

final restaurantRepositoryProvider =
    Provider<SupabaseRestaurantRepository>((ref) {
  return SupabaseRestaurantRepository(
    ref.watch(supabaseClientProvider),
    restaurantIdProvider: () => ref.watch(currentRestaurantIdProvider),
  );
});

/// Holds the restaurant profile + the actual tables count side by side so the
/// UI can warn when the manual `totalTables` diverges from reality.
class RestaurantSettingsState {
  const RestaurantSettingsState({
    required this.restaurant,
    this.actualTablesCount,
  });

  final RestaurantEntity restaurant;
  final int? actualTablesCount;

  bool get hasDivergence =>
      actualTablesCount != null &&
      actualTablesCount != restaurant.totalTables;

  bool get manualBelowActual =>
      actualTablesCount != null &&
      restaurant.totalTables < actualTablesCount!;
}

class RestaurantSettingsController
    extends AsyncNotifier<RestaurantSettingsState> {
  @override
  Future<RestaurantSettingsState> build() async {
    final repo = ref.watch(restaurantRepositoryProvider);
    final restaurantResult = await repo.getRestaurant();
    return restaurantResult.when(
      onLeft: (failure) =>
          throw AsyncError(failure.message, StackTrace.current),
      onRight: (restaurant) => RestaurantSettingsState(restaurant: restaurant),
    );
  }

  /// Loads the actual `tables` count for the divergence banner.
  Future<void> loadActualTablesCount() async {
    final current = state.valueOrNull;
    if (current == null) return;
    final repo = ref.read(restaurantRepositoryProvider);
    final result = await repo.getActualTablesCount();
    result.when(
      onLeft: (_) {},
      onRight: (count) {
        state = AsyncData(
          RestaurantSettingsState(
            restaurant: current.restaurant,
            actualTablesCount: count,
          ),
        );
      },
    );
  }

  /// Copies the actual tables count into the manual field (explicit sync).
  Future<void> syncTotalTablesFromActual() async {
    final current = state.valueOrNull;
    final actual = current?.actualTablesCount;
    if (current == null || actual == null) return;
    await save(
      name: current.restaurant.name,
      address: current.restaurant.address,
      phone: current.restaurant.phone,
      openTime: current.restaurant.hours.openTime,
      closeTime: current.restaurant.hours.closeTime,
      latitude: current.restaurant.latitude,
      longitude: current.restaurant.longitude,
      totalTables: actual,
    );
  }

  static int? _parseTimeToMinutes(String time) {
    final parts = time.trim().split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return null;
    }
    return h * 60 + m;
  }

  Future<bool> save({
    required String name,
    required String address,
    required String phone,
    required String openTime,
    required String closeTime,
    required double latitude,
    required double longitude,
    required int totalTables,
  }) async {
    final current = state.valueOrNull;
    final actual = current?.actualTablesCount;

    // Guard: Egyptian phone validation
    final cleanPhone = phone.trim().replaceAll(' ', '');
    final phoneRegex = RegExp(r'^(\+201|01)[0125]\d{8}$');
    if (!phoneRegex.hasMatch(cleanPhone)) {
      state = AsyncError('رقم الهاتف غير صالح (يجب أن يكون رقم مصري يبدأ بـ 010, 011, 012, 015)', StackTrace.current);
      return false;
    }

    // Guard: operating hours
    final openMinutes = _parseTimeToMinutes(openTime);
    final closeMinutes = _parseTimeToMinutes(closeTime);
    if (openMinutes == null || closeMinutes == null || openMinutes >= closeMinutes) {
      state = AsyncError('وقت الفتح يجب أن يكون قبل وقت الإغلاق (صيغة HH:MM)', StackTrace.current);
      return false;
    }

    // Guard: coordinates
    if (latitude < -90.0 || latitude > 90.0 || longitude < -180.0 || longitude > 180.0) {
      state = AsyncError('الإحداثيات الجغرافية غير صالحة', StackTrace.current);
      return false;
    }

    // Guard: total tables
    if (totalTables < 0) {
      state = AsyncError('عدد الطاولات يجب أن يكون 0 أو أكثر', StackTrace.current);
      return false;
    }

    // Guard: manual value may never go below the actual tables in Supabase.
    if (actual != null && totalTables < actual) {
      state = AsyncError('عدد الطاولات اليدوي لا يمكن أن يقل عن عدد الطاولات الفعلي ($actual)', StackTrace.current);
      return false;
    }

    state = const AsyncLoading();
    final repo = ref.read(restaurantRepositoryProvider);
    final result = await repo.updateRestaurant(
      name: name,
      address: address,
      phone: cleanPhone,
      openTime: openTime,
      closeTime: closeTime,
      latitude: latitude,
      longitude: longitude,
      totalTables: totalTables,
    );
    return result.when(
      onLeft: (failure) {
        state = AsyncError(failure.message, StackTrace.current);
        return false;
      },
      onRight: (restaurant) {
        state = AsyncData(
          RestaurantSettingsState(
            restaurant: restaurant,
            actualTablesCount: actual,
          ),
        );
        return true;
      },
    );
  }
}

final restaurantSettingsControllerProvider =
    AsyncNotifierProvider<RestaurantSettingsController,
        RestaurantSettingsState>(RestaurantSettingsController.new);
