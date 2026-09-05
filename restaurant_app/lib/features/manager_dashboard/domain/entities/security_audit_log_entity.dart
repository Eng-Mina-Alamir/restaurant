enum SecurityAuditEventType {
  orderVoid('إلغاء فاتورة / صنف (Void) 🚫'),
  noSaleDrawerOpen('فتح درج النقدية يدوي (No-Sale Drawer) 🔓'),
  priceOverride('تعديل سعر يدوي (Price Override) ✏️'),
  highDiscount('خصم استثنائي أو ضيافة (High Discount / Comp) 🏷️'),
  refundIssued('استرجاع نقدية للعميل (Cash Refund) 🔄'),
  managerPinOverride('استخدام PIN المدير للصلاحيات 🔑'),
  recipeModified('تعديل تكوين وصفة إنتاج 🥣');

  final String labelAr;
  const SecurityAuditEventType(this.labelAr);
}

enum AuditSeverity {
  info('معلوماتي ℹ️'),
  warning('تنبيه هام ⚠️'),
  critical('خطير / تدقيق عاجل 🚨');

  final String labelAr;
  const AuditSeverity(this.labelAr);
}

/// A recorded sensitive operational event for restaurant security and loss prevention.
class SecurityAuditLogEntry {
  const SecurityAuditLogEntry({
    required this.id,
    required this.type,
    required this.actionDescription,
    required this.staffName,
    required this.staffRole,
    required this.timestamp,
    this.severity = AuditSeverity.info,
    this.managerPinUsed,
    this.monetaryAmount,
    this.metadata = const {},
  });

  final String id;
  final SecurityAuditEventType type;
  final String actionDescription;
  final String staffName;
  final String staffRole;
  final DateTime timestamp;
  final AuditSeverity severity;
  final String? managerPinUsed;
  final double? monetaryAmount;
  final Map<String, dynamic> metadata;

  /// Preset sample demo security audit entries.
  static final List<SecurityAuditLogEntry> demoEntries = [
    SecurityAuditLogEntry(
      id: 'SEC-1',
      type: SecurityAuditEventType.orderVoid,
      actionDescription: 'إلغاء فاتورة #ORD-8412 بقيمة 450.00 ج.م بعد طباعة بون المطبخ',
      staffName: 'حسام علي',
      staffRole: 'كاشير',
      timestamp: DateTime.now().subtract(const Duration(minutes: 42)),
      severity: AuditSeverity.warning,
      monetaryAmount: 450.0,
      managerPinUsed: 'معتمد ✅',
    ),
    SecurityAuditLogEntry(
      id: 'SEC-2',
      type: SecurityAuditEventType.noSaleDrawerOpen,
      actionDescription: 'فتح درج النقدية يدوياً بدون تسجيل فاتورة مبيعات',
      staffName: 'حسام علي',
      staffRole: 'كاشير',
      timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
      severity: AuditSeverity.info,
    ),
    SecurityAuditLogEntry(
      id: 'SEC-3',
      type: SecurityAuditEventType.highDiscount,
      actionDescription: 'تطبيق ضيافة إدارة 100% Comp على طاولة #8 بقيمة 780.00 ج.م',
      staffName: 'أحمد شريف',
      staffRole: 'ويتر كابتن',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      severity: AuditSeverity.critical,
      monetaryAmount: 780.0,
      managerPinUsed: 'معتمد ✅',
    ),
  ];
}
