enum RatingTargetType {
  menuItem,
  driver,
  restaurant;

  String get labelAr {
    switch (this) {
      case RatingTargetType.menuItem:
        return 'تقييم الوجبة';
      case RatingTargetType.driver:
        return 'تقييم السائق';
      case RatingTargetType.restaurant:
        return 'تقييم المطعم';
    }
  }
}

/// Represents a customer rating and review.
class RatingEntity {
  const RatingEntity({
    required this.id,
    required this.targetId,
    required this.targetType,
    required this.userId,
    required this.userName,
    required this.score,
    this.comment,
    required this.createdAt,
  });

  final String id;
  final String targetId;
  final RatingTargetType targetType;
  final String userId;
  final String userName;
  final double score; // 1.0 to 5.0
  final String? comment;
  final DateTime createdAt;

  RatingEntity copyWith({
    String? id,
    String? targetId,
    RatingTargetType? targetType,
    String? userId,
    String? userName,
    double? score,
    String? comment,
    DateTime? createdAt,
  }) {
    return RatingEntity(
      id: id ?? this.id,
      targetId: targetId ?? this.targetId,
      targetType: targetType ?? this.targetType,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      score: score ?? this.score,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'targetId': targetId,
        'targetType': targetType.name,
        'userId': userId,
        'userName': userName,
        'score': score,
        'comment': comment,
        'createdAt': createdAt.toIso8601String(),
      };

  factory RatingEntity.fromJson(Map<String, dynamic> json) => RatingEntity(
        id: json['id'] as String,
        targetId: json['targetId'] as String,
        targetType: RatingTargetType.values.firstWhere(
          (e) => e.name == json['targetType'],
          orElse: () => RatingTargetType.menuItem,
        ),
        userId: json['userId'] as String,
        userName: json['userName'] as String,
        score: (json['score'] as num).toDouble(),
        comment: json['comment'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
