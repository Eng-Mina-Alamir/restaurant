enum DiscountType {
  percentage('نسبة مئوية (%)'),
  fixedAmount('مبلغ مالي ثابت (ج.م)'),
  staffMeal('وجبة موظفين (Staff Discount)'),
  complimentary('ضيافة إدارة (100% Comp)');

  final String labelAr;
  const DiscountType(this.labelAr);
}

/// A structured discount applied by the cashier or manager.
class CashierDiscount {
  const CashierDiscount({
    required this.id,
    required this.nameAr,
    required this.type,
    required this.value,
    this.requiresManagerPin = false,
    this.reason,
    this.customNote,
  });

  final String id;
  final String nameAr;
  final DiscountType type;
  final double value; // either percentage (e.g. 15.0) or fixed amount (e.g. 50.0)
  final bool requiresManagerPin;
  final String? reason;
  final String? customNote;

  /// Preset discount list for fast frontline restaurant cashier selection.
  static const List<CashierDiscount> presets = [
    CashierDiscount(
      id: 'disc-5',
      nameAr: 'خصم عميل 5%',
      type: DiscountType.percentage,
      value: 5.0,
    ),
    CashierDiscount(
      id: 'disc-10',
      nameAr: 'خصم ترويجي 10%',
      type: DiscountType.percentage,
      value: 10.0,
    ),
    CashierDiscount(
      id: 'disc-15',
      nameAr: 'خصم كبار الزوار 15%',
      type: DiscountType.percentage,
      value: 15.0,
      requiresManagerPin: true,
    ),
    CashierDiscount(
      id: 'disc-20',
      nameAr: 'خصم شراكة 20%',
      type: DiscountType.percentage,
      value: 20.0,
      requiresManagerPin: true,
    ),
    CashierDiscount(
      id: 'disc-staff',
      nameAr: 'خصم موظفي المطعم 30%',
      type: DiscountType.staffMeal,
      value: 30.0,
      requiresManagerPin: true,
    ),
    CashierDiscount(
      id: 'disc-comp',
      nameAr: 'ضيافة إدارة 100% (Complimentary)',
      type: DiscountType.complimentary,
      value: 100.0,
      requiresManagerPin: true,
    ),
  ];

  /// Calculates the monetary discount amount from the [subtotal].
  double calculateDiscountAmount(double subtotal) {
    if (subtotal <= 0) return 0.0;
    switch (type) {
      case DiscountType.percentage:
      case DiscountType.staffMeal:
        return (subtotal * (value / 100)).clamp(0.0, subtotal);
      case DiscountType.fixedAmount:
        return value.clamp(0.0, subtotal);
      case DiscountType.complimentary:
        return subtotal;
    }
  }
}
