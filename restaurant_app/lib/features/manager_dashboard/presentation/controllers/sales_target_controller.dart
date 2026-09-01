import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  SalesTargetController() : super(const SalesTargetState());

  /// Sets a new daily revenue target.
  void setDailyTarget(double target) {
    if (target > 0) {
      state = state.copyWith(dailyTarget: target);
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
      return SalesTargetController();
    });
