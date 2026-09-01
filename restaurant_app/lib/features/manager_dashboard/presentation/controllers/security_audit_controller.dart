import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/security_audit_log_entity.dart';
import '../../domain/services/security_audit_service.dart';

/// State of security logs and loss prevention alerts.
class SecurityAuditState {
  const SecurityAuditState({
    this.logs = const [],
    this.selectedSeverityFilter,
  });

  final List<SecurityAuditLogEntry> logs;
  final AuditSeverity? selectedSeverityFilter;

  List<SecurityAuditLogEntry> get filteredLogs =>
      SecurityAuditService.filterBySeverity(logs, selectedSeverityFilter);

  double get totalSensitiveAmounts =>
      SecurityAuditService.calculateTotalSensitiveDiscountsAndVoids(logs);

  int get noSaleDrawerOpenCount =>
      SecurityAuditService.countNoSaleDrawerOpens(logs);

  SecurityAuditState copyWith({
    List<SecurityAuditLogEntry>? logs,
    AuditSeverity? selectedSeverityFilter,
    bool clearFilter = false,
  }) {
    return SecurityAuditState(
      logs: logs ?? this.logs,
      selectedSeverityFilter:
          clearFilter ? null : (selectedSeverityFilter ?? this.selectedSeverityFilter),
    );
  }
}

/// Controller managing security audit log entries and fraud detection alerts.
class SecurityAuditController extends StateNotifier<SecurityAuditState> {
  SecurityAuditController()
      : super(
          SecurityAuditState(
            logs: List.from(SecurityAuditLogEntry.demoEntries),
          ),
        );

  /// Records a new sensitive operational security event.
  SecurityAuditLogEntry recordEvent({
    required SecurityAuditEventType type,
    required String actionDescription,
    required String staffName,
    required String staffRole,
    AuditSeverity severity = AuditSeverity.info,
    String? managerPinUsed,
    double? monetaryAmount,
    Map<String, dynamic> metadata = const {},
  }) {
    final entry = SecurityAuditLogEntry(
      id: 'SEC-${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      actionDescription: actionDescription,
      staffName: staffName,
      staffRole: staffRole,
      timestamp: DateTime.now(),
      severity: severity,
      managerPinUsed: managerPinUsed,
      monetaryAmount: monetaryAmount,
      metadata: metadata,
    );

    state = state.copyWith(logs: [entry, ...state.logs]);
    return entry;
  }

  /// Sets severity filter.
  void setSeverityFilter(AuditSeverity? severity) {
    if (severity == null) {
      state = state.copyWith(clearFilter: true);
    } else {
      state = state.copyWith(selectedSeverityFilter: severity);
    }
  }
}

/// Riverpod provider for [SecurityAuditController].
final securityAuditControllerProvider =
    StateNotifierProvider<SecurityAuditController, SecurityAuditState>((ref) {
      return SecurityAuditController();
    });
