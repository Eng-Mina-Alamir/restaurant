/// Customer feedback, rating, and complaint resolution record.
class GuestFeedback {
  const GuestFeedback({
    required this.id,
    required this.orderId,
    required this.customerName,
    required this.customerPhone,
    required this.overallRating, // 1 to 5
    this.foodQualityRating = 5,
    this.serviceSpeedRating = 5,
    this.cleanlinessRating = 5,
    required this.comment,
    required this.createdAt,
    this.isResolved = false,
    this.resolutionNotes,
    this.compensationCouponCode,
  });

  final String id;
  final String orderId;
  final String customerName;
  final String customerPhone;
  final int overallRating;
  final int foodQualityRating;
  final int serviceSpeedRating;
  final int cleanlinessRating;
  final String comment;
  final DateTime createdAt;
  final bool isResolved;
  final String? resolutionNotes;
  final String? compensationCouponCode;

  bool get isNegative => overallRating <= 3;

  GuestFeedback copyWith({
    String? id,
    String? orderId,
    String? customerName,
    String? customerPhone,
    int? overallRating,
    int? foodQualityRating,
    int? serviceSpeedRating,
    int? cleanlinessRating,
    String? comment,
    DateTime? createdAt,
    bool? isResolved,
    String? resolutionNotes,
    String? compensationCouponCode,
  }) {
    return GuestFeedback(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      overallRating: overallRating ?? this.overallRating,
      foodQualityRating: foodQualityRating ?? this.foodQualityRating,
      serviceSpeedRating: serviceSpeedRating ?? this.serviceSpeedRating,
      cleanlinessRating: cleanlinessRating ?? this.cleanlinessRating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      isResolved: isResolved ?? this.isResolved,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      compensationCouponCode: compensationCouponCode ?? this.compensationCouponCode,
    );
  }

  /// Sample demo feedback entries.
  static final List<GuestFeedback> demoFeedbacks = [
    GuestFeedback(
      id: 'FB-1',
      orderId: 'ORD-771',
      customerName: 'مريم عادل',
      customerPhone: '01011223344',
      overallRating: 5,
      foodQualityRating: 5,
      serviceSpeedRating: 5,
      cleanlinessRating: 5,
      comment: 'الأكل رائع جداً وساخن وخدمة الكابتن كانت ممتازة وسريعة!',
      createdAt: DateTime.now().subtract(const Duration(minutes: 35)),
    ),
    GuestFeedback(
      id: 'FB-2',
      orderId: 'ORD-768',
      customerName: 'كريم عبد العزيز',
      customerPhone: '01122334455',
      overallRating: 2,
      foodQualityRating: 4,
      serviceSpeedRating: 2,
      cleanlinessRating: 3,
      comment: 'الطلب تأخر أكثر من 45 دقيقة على الطاولة والشوربة وصلت باردة.',
      createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 10)),
      isResolved: false,
    ),
    GuestFeedback(
      id: 'FB-3',
      orderId: 'ORD-750',
      customerName: 'نهى الصاوي',
      customerPhone: '01233445566',
      overallRating: 4,
      foodQualityRating: 5,
      serviceSpeedRating: 4,
      cleanlinessRating: 4,
      comment: 'تجربة جيدة جداً ونكهة الشاورما ممتازة، شكراً لفريق العمل.',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
  ];
}

/// Aggregated guest satisfaction breakdown metrics.
class FeedbackMetrics {
  const FeedbackMetrics({
    required this.averageOverallRating,
    required this.averageFoodQuality,
    required this.averageServiceSpeed,
    required this.averageCleanliness,
    required this.totalReviewsCount,
    required this.csatPercentage,
    required this.unresolvedComplaintsCount,
  });

  final double averageOverallRating;
  final double averageFoodQuality;
  final double averageServiceSpeed;
  final double averageCleanliness;
  final int totalReviewsCount;
  final double csatPercentage;
  final int unresolvedComplaintsCount;
}
