/// Record of a table transfer action (moving an active order from Table A to Table B).
class TableTransferRecord {
  const TableTransferRecord({
    required this.id,
    required this.orderId,
    required this.fromTableId,
    required this.fromTableNumber,
    required this.toTableId,
    required this.toTableNumber,
    required this.waiterId,
    required this.transferredAt,
    this.reason = 'طلب الضيوف تغيير مكان الجلوس',
  });

  final String id;
  final String orderId;
  final String fromTableId;
  final int fromTableNumber;
  final String toTableId;
  final int toTableNumber;
  final String waiterId;
  final DateTime transferredAt;
  final String reason;

  Map<String, dynamic> toJson() => {
    'id': id,
    'orderId': orderId,
    'fromTableId': fromTableId,
    'fromTableNumber': fromTableNumber,
    'toTableId': toTableId,
    'toTableNumber': toTableNumber,
    'waiterId': waiterId,
    'transferredAt': transferredAt.toIso8601String(),
    'reason': reason,
  };

  factory TableTransferRecord.fromJson(Map<String, dynamic> json) {
    return TableTransferRecord(
      id: json['id'] as String,
      orderId: json['orderId'] as String,
      fromTableId: json['fromTableId'] as String,
      fromTableNumber: json['fromTableNumber'] as int,
      toTableId: json['toTableId'] as String,
      toTableNumber: json['toTableNumber'] as int,
      waiterId: json['waiterId'] as String,
      transferredAt: DateTime.parse(json['transferredAt'] as String),
      reason: json['reason'] as String? ?? 'طلب الضيوف تغيير مكان الجلوس',
    );
  }
}

/// Record of merged tables for large groups and banquets.
class TableMergeRecord {
  const TableMergeRecord({
    required this.id,
    required this.primaryTableId,
    required this.primaryTableNumber,
    required this.secondaryTableIds,
    required this.secondaryTableNumbers,
    required this.totalCapacity,
    required this.mergedAt,
    this.linkedOrderId,
  });

  final String id;
  final String primaryTableId;
  final int primaryTableNumber;
  final List<String> secondaryTableIds;
  final List<int> secondaryTableNumbers;
  final int totalCapacity;
  final DateTime mergedAt;
  final String? linkedOrderId;

  String get displayName {
    final secondaries = secondaryTableNumbers.join(' + ');
    return 'طاولة $primaryTableNumber (مدمجة مع $secondaries)';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'primaryTableId': primaryTableId,
    'primaryTableNumber': primaryTableNumber,
    'secondaryTableIds': secondaryTableIds,
    'secondaryTableNumbers': secondaryTableNumbers,
    'totalCapacity': totalCapacity,
    'mergedAt': mergedAt.toIso8601String(),
    'linkedOrderId': linkedOrderId,
  };

  factory TableMergeRecord.fromJson(Map<String, dynamic> json) {
    return TableMergeRecord(
      id: json['id'] as String,
      primaryTableId: json['primaryTableId'] as String,
      primaryTableNumber: json['primaryTableNumber'] as int,
      secondaryTableIds:
          (json['secondaryTableIds'] as List<dynamic>)
              .map((e) => e.toString())
              .toList(),
      secondaryTableNumbers:
          (json['secondaryTableNumbers'] as List<dynamic>)
              .map((e) => e as int)
              .toList(),
      totalCapacity: json['totalCapacity'] as int,
      mergedAt: DateTime.parse(json['mergedAt'] as String),
      linkedOrderId: json['linkedOrderId'] as String?,
    );
  }
}
