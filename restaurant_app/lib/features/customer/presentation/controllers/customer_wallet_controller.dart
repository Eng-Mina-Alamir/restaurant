import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../data/repositories/supabase_customer_profile_repository.dart';
import '../../domain/entities/customer_wallet_entity.dart';

export '../../domain/entities/customer_wallet_entity.dart';

class CustomerWalletNotifier extends StateNotifier<CustomerWalletState> {
  CustomerWalletNotifier([this._repository, this._userId])
      : super(const CustomerWalletState()) {
    loadWallet();
  }

  final SupabaseCustomerProfileRepository? _repository;
  final String? _userId;

  Future<void> loadWallet() async {
    if (_repository == null || _userId == null) return;
    final result = await _repository.getWallet(_userId);
    result.when(
      onLeft: (_) {},
      onRight: (CustomerWalletState wallet) {
        if (mounted) state = wallet;
      },
    );
  }

  /// Adds funds to the customer wallet (e.g. from gift card redemption or top-up)
  void addFunds(double amount, {required String title}) {
    if (amount <= 0) return;
    final newBalance = state.balance + amount;
    final tx = WalletTransaction(
      id: 'TX-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      amount: amount,
      date: DateTime.now(),
      isCredit: true,
    );
    state = state.copyWith(
      balance: newBalance,
      transactions: [tx, ...state.transactions],
    );
    if (_userId != null) {
      _repository?.addFunds(_userId, amount, title: title);
    }
  }

  /// Deducts funds from the wallet (e.g. when used to pay for an order)
  bool deductFunds(double amount, {required String title}) {
    if (amount <= 0) return false;
    if (state.balance < amount) return false;

    final newBalance = state.balance - amount;
    final tx = WalletTransaction(
      id: 'TX-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      amount: amount,
      date: DateTime.now(),
      isCredit: false,
    );
    state = state.copyWith(
      balance: newBalance,
      transactions: [tx, ...state.transactions],
    );
    return true;
  }
}

final customerWalletProvider =
    StateNotifierProvider<CustomerWalletNotifier, CustomerWalletState>((ref) {
  final repo = ref.watch(supabaseCustomerProfileRepositoryProvider);
  final user = ref.watch(supabaseCurrentUserProvider);
  return CustomerWalletNotifier(repo, user?.id);
});

/// Direct selector for the raw wallet balance number
final customerWalletBalanceProvider = Provider<double>((ref) {
  return ref.watch(customerWalletProvider).balance;
});

/// Direct selector for customer reward loyalty points
final customerLoyaltyPointsProvider = Provider<int>((ref) {
  return 150;
});
