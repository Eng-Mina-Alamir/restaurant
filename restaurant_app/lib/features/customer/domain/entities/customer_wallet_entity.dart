class WalletTransaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final bool isCredit;

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
