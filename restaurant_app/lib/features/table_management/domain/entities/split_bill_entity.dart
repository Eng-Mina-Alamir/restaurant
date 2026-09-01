import '../../../../core/domain/enums.dart';

/// Supported types of bill splitting.
enum SplitBillType {
  /// Equal division across N guests.
  equal('تقسيم متساوي'),

  /// Split according to seat numbers.
  bySeat('حسب رقم المقعد'),

  /// Split according to custom item selection.
  byItem('حسب الأصناف المختارة'),

  /// Split by custom manually entered amounts.
  custom('مبالغ مخصصة');

  const SplitBillType(this.labelAr);
  final String labelAr;
}

/// Represents a single guest's share of a split bill.
class SplitBillShare {
  const SplitBillShare({
    required this.shareIndex,
    required this.guestLabel,
    required this.subtotal,
    required this.taxAmount,
    required this.serviceAmount,
    required this.tipAmount,
    required this.totalAmount,
    this.seatNumber,
    this.itemNames = const <String>[],
    this.paymentMethod = PaymentMethod.cash,
    this.isPaid = false,
    this.paidAt,
  });

  final int shareIndex;
  final String guestLabel;
  final double subtotal;
  final double taxAmount;
  final double serviceAmount;
  final double tipAmount;
  final double totalAmount;
  final int? seatNumber;
  final List<String> itemNames;
  final PaymentMethod paymentMethod;
  final bool isPaid;
  final DateTime? paidAt;

  SplitBillShare copyWith({
    int? shareIndex,
    String? guestLabel,
    double? subtotal,
    double? taxAmount,
    double? serviceAmount,
    double? tipAmount,
    double? totalAmount,
    int? seatNumber,
    List<String>? itemNames,
    PaymentMethod? paymentMethod,
    bool? isPaid,
    DateTime? paidAt,
  }) {
    return SplitBillShare(
      shareIndex: shareIndex ?? this.shareIndex,
      guestLabel: guestLabel ?? this.guestLabel,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      serviceAmount: serviceAmount ?? this.serviceAmount,
      tipAmount: tipAmount ?? this.tipAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      seatNumber: seatNumber ?? this.seatNumber,
      itemNames: itemNames ?? this.itemNames,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isPaid: isPaid ?? this.isPaid,
      paidAt: paidAt ?? this.paidAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'shareIndex': shareIndex,
    'guestLabel': guestLabel,
    'subtotal': subtotal,
    'taxAmount': taxAmount,
    'serviceAmount': serviceAmount,
    'tipAmount': tipAmount,
    'totalAmount': totalAmount,
    'seatNumber': seatNumber,
    'itemNames': itemNames,
    'paymentMethod': paymentMethod.name,
    'isPaid': isPaid,
    'paidAt': paidAt?.toIso8601String(),
  };

  factory SplitBillShare.fromJson(Map<String, dynamic> json) {
    return SplitBillShare(
      shareIndex: json['shareIndex'] as int,
      guestLabel: json['guestLabel'] as String,
      subtotal: (json['subtotal'] as num).toDouble(),
      taxAmount: (json['taxAmount'] as num).toDouble(),
      serviceAmount: (json['serviceAmount'] as num).toDouble(),
      tipAmount: (json['tipAmount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      seatNumber: json['seatNumber'] as int?,
      itemNames:
          (json['itemNames'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == json['paymentMethod'],
        orElse: () => PaymentMethod.cash,
      ),
      isPaid: json['isPaid'] as bool? ?? false,
      paidAt:
          json['paidAt'] != null
              ? DateTime.parse(json['paidAt'] as String)
              : null,
    );
  }
}

/// Overall outcome and summary of a split bill session.
class SplitBillResult {
  const SplitBillResult({
    required this.orderId,
    required this.originalTotal,
    required this.splitType,
    required this.shares,
    this.notes,
  });

  final String orderId;
  final double originalTotal;
  final SplitBillType splitType;
  final List<SplitBillShare> shares;
  final String? notes;

  double get totalPaid => shares
      .where((s) => s.isPaid)
      .fold(0.0, (acc, s) => acc + s.totalAmount);

  double get remainingDue => originalTotal - totalPaid;

  bool get isFullySettled =>
      shares.isNotEmpty && shares.every((s) => s.isPaid);

  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'originalTotal': originalTotal,
    'splitType': splitType.name,
    'shares': shares.map((s) => s.toJson()).toList(),
    'notes': notes,
  };
}
