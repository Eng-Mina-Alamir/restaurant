import '../entities/security_audit_log_entity.dart';

/// Pure domain service evaluating security threats, voids, drawer anomalies, and price tampering.
abstract final class SecurityAuditService {
  SecurityAuditService._();

  /// Filters logs by severity level.
  static List<SecurityAuditLogEntry> filterBySeverity(
    List<SecurityAuditLogEntry> logs,
    AuditSeverity? severity,
  ) {
    if (severity == null) return logs;
    return logs.where((l) => l.severity == severity).toList();
  }

  /// Calculates total monetary loss associated with voids, high comps, and unauthorized discounts.
  static double calculateTotalSensitiveDiscountsAndVoids(List<SecurityAuditLogEntry> logs) {
    return logs
        .where((l) =>
            l.type == SecurityAuditEventType.orderVoid ||
            l.type == SecurityAuditEventType.highDiscount ||
            l.type == SecurityAuditEventType.refundIssued)
        .fold<double>(0.0, (acc, l) => acc + (l.monetaryAmount ?? 0.0));
  }

  /// Counts no-sale cash drawer opens during the day.
  static int countNoSaleDrawerOpens(List<SecurityAuditLogEntry> logs) {
    return logs.where((l) => l.type == SecurityAuditEventType.noSaleDrawerOpen).length;
  }
}
