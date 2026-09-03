import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/app_config.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../core/utils/logger.dart';
import '../../../orders/domain/entities/order_entity.dart';
import '../../domain/entities/hourly_sales_target_entity.dart';
import '../../domain/services/sales_velocity_service.dart';

/// State of restaurant sales targets and hourly performance velocity.
class SalesTargetState {
  const SalesTargetState({
    this.dailyTarget = 15000.0, // default 15,000 EGP / day
    this.monthlyTarget = 450000.0,
  });

  final double dailyTarget;
  final double monthlyTarget;

  DailyTargetProgress computeDailyProgress(List<OrderEntity> completedOrders) {
    return SalesVelocityService.calculateDailyProgress(
      completedOrders: completedOrders,
      dailyTarget: dailyTarget,
    );
  }

  SalesTargetState copyWith({
    double? dailyTarget,
    double? monthlyTarget,
  }) {
    return SalesTargetState(
      dailyTarget: dailyTarget ?? this.dailyTarget,
      monthlyTarget: monthlyTarget ?? this.monthlyTarget,
    );
  }
}

/// Controller managing revenue goals and sales velocity tracking.
class SalesTargetController extends StateNotifier<SalesTargetState> {
  SalesTargetController({SupabaseClient? supabase})
      : _supabase = supabase,
        super(const SalesTargetState()) {
    if (_supabase != null) {
      _loadFromSupabase();
    }
  }

  final SupabaseClient? _supabase;

  Future<void> _loadFromSupabase() async {
    final client = _supabase;
    if (client == null) return;
    try {
      final row = await client
          .from('sales_targets')
          .select()
          .order('target_date', ascending: false)
          .limit(1)
          .maybeSingle();

      if (row != null) {
        final daily = (row['daily_total_target'] as num?)?.toDouble() ?? 15000.0;
        state = state.copyWith(
          dailyTarget: daily,
          monthlyTarget: daily * 30,
        );
      }
    } catch (e) {
      AppLogger.warning('SalesTargetController loadFromSupabase error: $e');
    }
  }

  void _syncToSupabase(double newDaily) {
    final client = _supabase;
    if (client == null) return;
    Future.microtask(() async {
      try {
        await client.from('sales_targets').upsert({
          'restaurant_id': '1e08b47c-15be-4604-a913-431af7fbd54f',
          'target_date': DateTime.now().toIso8601String().split('T').first,
          'daily_total_target': newDaily,
          'hourly_targets_json': {},
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        AppLogger.warning('SalesTarget syncToSupabase error: $e');
      }
    });
  }

  /// Sets a new daily revenue target.
  void setDailyTarget(double target) {
    if (target > 0) {
      state = state.copyWith(dailyTarget: target);
      _syncToSupabase(target);
    }
  }

  /// Sets a new monthly revenue target.
  void setMonthlyTarget(double target) {
    if (target > 0) {
      state = state.copyWith(monthlyTarget: target);
    }
  }
}

/// Riverpod provider for [SalesTargetController].
final salesTargetControllerProvider =
    StateNotifierProvider<SalesTargetController, SalesTargetState>((ref) {
      final supabase = AppConfig.useSupabase ? ref.watch(supabaseClientProvider) : null;
      return SalesTargetController(supabase: supabase);
    });
