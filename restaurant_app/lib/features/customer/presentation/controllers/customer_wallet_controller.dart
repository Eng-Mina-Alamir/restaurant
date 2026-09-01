import 'package:flutter_riverpod/flutter_riverpod.dart';

class WalletTransaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final bool isCredit; // true = added, false = spent

  const WalletTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.isCredit,
  });
}

class CustomerWalletState {
  final double balance;
  final List<WalletTransaction> transactions;

  const CustomerWalletState({
    this.balance = 0.0,
    this.transactions = const [],
  });

  CustomerWalletState copyWith({
    double? balance,
    List<WalletTransaction>? transactions,
  }) {
    return CustomerWalletState(
      balance: balance ?? this.balance,
      transactions: transactions ?? this.transactions,
    );
  }
}

class CustomerWalletNotifier extends StateNotifier<CustomerWalletState> {
  CustomerWalletNotifier()
      : super(
          CustomerWalletState(
            balance: 0.0,
            transactions: [
              WalletTransaction(
                id: 'TX-INIT',
                title: 'رصيد ترحيبي مبدئي',
                amount: 0.0,
                date: DateTime.now(),
                isCredit: true,
              ),
            ],
          ),
        );

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
  return CustomerWalletNotifier();
});

/// Direct selector for the raw wallet balance number
final customerWalletBalanceProvider = Provider<double>((ref) {
  return ref.watch(customerWalletProvider).balance;
});

/// Direct selector for customer reward loyalty points
final customerLoyaltyPointsProvider = Provider<int>((ref) {
  return 150;
});
