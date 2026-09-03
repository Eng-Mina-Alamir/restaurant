import '../../../../core/utils/financial_calculator.dart';
import '../../../../core/utils/formatters.dart';

enum CouponDiscountType {
  percentage('نسبة مئوية (%)'),
  fixed('مبلغ ثابت نقدي');

  final String labelAr;
  const CouponDiscountType(this.labelAr);
}

class CouponEntity {
  final String id;
  final String code;
  final String title;
  final CouponDiscountType discountType;
  final double discountValue;
  final double minOrderAmount;
  final double? maxDiscountAmount;
  final DateTime? validUntil;
  final int? usageLimit;
  final int usageCount;
  final bool isActive;

  const CouponEntity({
    required this.id,
    required this.code,
    required this.title,
    required this.discountType,
    required this.discountValue,
    this.minOrderAmount = 0.0,
    this.maxDiscountAmount,
    this.validUntil,
    this.usageLimit,
    this.usageCount = 0,
    this.isActive = true,
  });

  /// Normalizes and checks if [inputCode] matches this coupon's code
  /// (case-insensitive and trimmed).
  bool matchesCode(String? inputCode) {
    if (inputCode == null) return false;
    return code.trim().toUpperCase() == inputCode.trim().toUpperCase();
  }

  /// Validates if coupon is currently valid for the given order subtotal.
  /// Returns null if valid, or error message string if invalid.
  String? validate(double subtotal) {
    if (!isActive) {
      return 'كود الخصم غير مفعّل حالياً';
    }
    if (validUntil != null && DateTime.now().isAfter(validUntil!)) {
      return 'عفواً، لقد انتهت صلاحية هذا الكود';
    }
    if (usageLimit != null && usageCount >= usageLimit!) {
      return 'لقد تم الوصول للحد الأقصى لاستخدام هذا الكود';
    }
    if (subtotal < minOrderAmount) {
      return 'الحد الأدنى لتطبيق هذا الكود هو ${Formatters.formatCurrency(minOrderAmount)}';
    }
    return null;
  }

  /// Computes the exact discount amount in SAR for the given subtotal.
  double calculateDiscount(double subtotal) {
    if (subtotal <= 0) return 0.0;
    if (validate(subtotal) != null) return 0.0;

    double discount = 0.0;
    if (discountType == CouponDiscountType.percentage) {
      discount = FinancialCalculator.calculatePercentageDiscount(
        subtotal: subtotal,
        percentage: discountValue,
        maxDiscount: maxDiscountAmount,
      );
    } else {
      discount = FinancialCalculator.roundCurrency(discountValue);
    }

    if (discount > subtotal) {
      discount = subtotal;
    }
    return FinancialCalculator.roundCurrency(discount.clamp(0.0, subtotal));
  }

  CouponEntity copyWith({
    String? id,
    String? code,
    String? title,
    CouponDiscountType? discountType,
    double? discountValue,
    double? minOrderAmount,
    double? maxDiscountAmount,
    DateTime? validUntil,
    int? usageLimit,
    int? usageCount,
    bool? isActive,
  }) {
    return CouponEntity(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      minOrderAmount: minOrderAmount ?? this.minOrderAmount,
      maxDiscountAmount: maxDiscountAmount ?? this.maxDiscountAmount,
      validUntil: validUntil ?? this.validUntil,
      usageLimit: usageLimit ?? this.usageLimit,
      usageCount: usageCount ?? this.usageCount,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'title': title,
    'discountType': discountType.name,
    'discountValue': discountValue,
    'minOrderAmount': minOrderAmount,
    'maxDiscountAmount': maxDiscountAmount,
    'validUntil': validUntil?.toIso8601String(),
    'usageLimit': usageLimit,
    'usageCount': usageCount,
    'isActive': isActive,
  };

  factory CouponEntity.fromJson(Map<String, dynamic> json) => CouponEntity(
    id: json['id'] as String,
    code: json['code'] as String,
    title: json['title'] as String,
    discountType: CouponDiscountType.values.firstWhere(
      (e) => e.name == json['discountType'],
      orElse: () => CouponDiscountType.percentage,
    ),
    discountValue: (json['discountValue'] as num?)?.toDouble() ?? 0.0,
    minOrderAmount: (json['minOrderAmount'] as num?)?.toDouble() ?? 0.0,
    maxDiscountAmount: (json['maxDiscountAmount'] as num?)?.toDouble(),
    validUntil: json['validUntil'] != null
        ? DateTime.tryParse(json['validUntil'] as String)
        : null,
    usageLimit: (json['usageLimit'] as num?)?.toInt(),
    usageCount: (json['usageCount'] as num?)?.toInt() ?? 0,
    isActive: json['isActive'] as bool? ?? true,
  );
}
