import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/app_config.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../data/repositories/in_memory_loyalty_repository.dart';
import '../../data/repositories/supabase_loyalty_repository.dart';
import '../../domain/entities/loyalty_entity.dart';
import '../../domain/repositories/loyalty_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

final loyaltyRepositoryProvider = Provider<LoyaltyRepository>((ref) {
  if (AppConfig.useSupabase) {
    return SupabaseLoyaltyRepository(
      supabase: ref.watch(supabaseClientProvider),
    );
  }
  return InMemoryLoyaltyRepository();
});

final availableRewardsProvider = FutureProvider<List<LoyaltyReward>>((
  ref,
) async {
  final repo = ref.watch(loyaltyRepositoryProvider);
  final result = await repo.getAvailableRewards();
  return result.when(onLeft: (_) => [], onRight: (rewards) => rewards);
});

class LoyaltyController extends StateNotifier<AsyncValue<LoyaltyAccount>> {
  final LoyaltyRepository _repository;
  final String _userId;

  LoyaltyController({
    required LoyaltyRepository repository,
    required String userId,
  }) : _repository = repository,
       _userId = userId,
       super(const AsyncValue.loading()) {
    loadAccount();
  }

  Future<void> loadAccount() async {
    state = const AsyncValue.loading();
    final result = await _repository.getAccount(_userId);
    if (!mounted) return;
    result.when(
      onLeft: (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
      onRight: (account) => state = AsyncValue.data(account),
    );
  }

  Future<bool> redeemReward(LoyaltyReward reward) async {
    final result = await _repository.redeemReward(
      userId: _userId,
      reward: reward,
    );
    if (!mounted) return false;
    return result.when(
      onLeft: (failure) => false,
      onRight: (updated) {
        state = AsyncValue.data(updated);
        return true;
      },
    );
  }

  Future<void> earnPoints({
    required double orderTotal,
    required String orderId,
  }) async {
    final result = await _repository.earnPoints(
      userId: _userId,
      orderTotal: orderTotal,
      orderId: orderId,
    );
    if (!mounted) return;
    result.when(
      onLeft: (_) {},
      onRight: (updated) => state = AsyncValue.data(updated),
    );
  }
}

final loyaltyControllerProvider =
    StateNotifierProvider<LoyaltyController, AsyncValue<LoyaltyAccount>>((ref) {
      final repo = ref.watch(loyaltyRepositoryProvider);
      final user = ref.watch(authControllerProvider).user;
      final userId = user?.id ?? 'guest-customer';
      return LoyaltyController(repository: repo, userId: userId);
    });
