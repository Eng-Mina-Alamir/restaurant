/// Severity level for operational restaurant alerts.
enum AlertSeverity { critical, warning, info }

/// Operational area generating the alert.
enum AlertCategory {
  all('الكل'),
  inventory('المخزون'),
  kitchenDelay('تأخير المطبخ'),
  delivery('التوصيل'),
  system('النظام');

  const AlertCategory(this.displayName);
  final String displayName;
}

/// A structured notification / operational alert in the manager alert center.
class AlertEntity {
  const AlertEntity({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.category,
    required this.createdAt,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String message;
  final AlertSeverity severity;
  final AlertCategory category;
  final DateTime createdAt;
  final bool isRead;

  AlertEntity copyWith({
    String? id,
    String? title,
    String? message,
    AlertSeverity? severity,
    AlertCategory? category,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return AlertEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      severity: severity ?? this.severity,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
