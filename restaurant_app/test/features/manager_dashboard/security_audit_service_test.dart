import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/manager_dashboard/domain/entities/security_audit_log_entity.dart';
import 'package:restaurant_app/features/manager_dashboard/domain/services/security_audit_service.dart';

void main() {
  group('SecurityAuditService Tests', () {
    test('Filters logs by severity and detects critical loss events', () {
      final logs = [
        SecurityAuditLogEntry(
          id: 'SEC-1',
          type: SecurityAuditEventType.orderVoid,
          actionDescription: 'إلغاء فاتورة',
          staffName: 'كاشير 1',
          staffRole: 'كاشير',
          timestamp: DateTime.now(),
          severity: AuditSeverity.critical,
          monetaryAmount: 500.0,
        ),
        SecurityAuditLogEntry(
          id: 'SEC-2',
          type: SecurityAuditEventType.noSaleDrawerOpen,
          actionDescription: 'فتح درج يدوي',
          staffName: 'كاشير 1',
          staffRole: 'كاشير',
          timestamp: DateTime.now(),
          severity: AuditSeverity.info,
        ),
        SecurityAuditLogEntry(
          id: 'SEC-3',
          type: SecurityAuditEventType.highDiscount,
          actionDescription: 'ضيافة إدارة',
          staffName: 'كابتن 1',
          staffRole: 'ويتر',
          timestamp: DateTime.now(),
          severity: AuditSeverity.warning,
          monetaryAmount: 250.0,
        ),
      ];

      final criticalLogs = SecurityAuditService.filterBySeverity(logs, AuditSeverity.critical);
      expect(criticalLogs.length, 1);
      expect(criticalLogs.first.id, 'SEC-1');

      final totalLoss = SecurityAuditService.calculateTotalSensitiveDiscountsAndVoids(logs);
      expect(totalLoss, 750.0);

      final noSaleCount = SecurityAuditService.countNoSaleDrawerOpens(logs);
      expect(noSaleCount, 1);
    });
  });
}
