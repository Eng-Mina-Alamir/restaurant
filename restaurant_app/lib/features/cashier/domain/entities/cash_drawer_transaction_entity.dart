enum CashDrawerTransactionType {
  payIn('إيداع نقدية بالدرج (Pay-In)'),
  payOut('سحب مصروفات نثرية (Pay-Out)');

  final String labelAr;
  const CashDrawerTransactionType(this.labelAr);
}

/// A recorded cash drawer movement (Pay-In / Pay-Out / Petty Cash).
class CashDrawerTransaction {
  const CashDrawerTransaction({
    required this.id,
    required this.shiftId,
    required this.type,
    required this.amount,
    required this.reason,
    required this.timestamp,
    this.recipientOrDepositor,
    this.authorizedByManagerPin,
  });

  final String id;
  final String shiftId;
  final CashDrawerTransactionType type;
  final double amount;
  final String reason;
  final DateTime timestamp;
  final String? recipientOrDepositor;
  final String? authorizedByManagerPin;

  CashDrawerTransaction copyWith({
    String? id,
    String? shiftId,
    CashDrawerTransactionType? type,
    double? amount,
    String? reason,
    DateTime? timestamp,
    String? recipientOrDepositor,
    String? authorizedByManagerPin,
  }) {
    return CashDrawerTransaction(
      id: id ?? this.id,
      shiftId: shiftId ?? this.shiftId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      reason: reason ?? this.reason,
      timestamp: timestamp ?? this.timestamp,
      recipientOrDepositor: recipientOrDepositor ?? this.recipientOrDepositor,
      authorizedByManagerPin:
          authorizedByManagerPin ?? this.authorizedByManagerPin,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'shiftId': shiftId,
    'type': type.name,
    'amount': amount,
    'reason': reason,
    'timestamp': timestamp.toIso8601String(),
    'recipientOrDepositor': recipientOrDepositor,
    'authorizedByManagerPin': authorizedByManagerPin,
  };
}
