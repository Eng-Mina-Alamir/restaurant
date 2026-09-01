/// Reasons for logging food or ingredient waste/spoilage.
enum WasteReason {
  expired('منتهي الصلاحية'),
  preparationError('خطأ أثناء الطهي/التحضير'),
  customerReturn('مرتجع من العميل'),
  spoilage('تالف بسبب التخزين/البرودة'),
  damagedDelivery('تالف أثناء التوريد'),
  other('أسباب أخرى');

  final String labelAr;
  const WasteReason(this.labelAr);
}

/// Represents a logged record of spoiled, damaged, or wasted inventory items.
class WasteLogEntity {
  const WasteLogEntity({
    required this.id,
    required this.inventoryItemId,
    required this.inventoryItemName,
    required this.quantity,
    required this.unit,
    required this.unitCost,
    required this.totalCost,
    required this.reason,
    required this.loggedByName,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final String inventoryItemId;
  final String inventoryItemName;
  final double quantity;
  final String unit;
  final double unitCost;
  final double totalCost;
  final WasteReason reason;
  final String loggedByName;
  final String? notes;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'inventoryItemId': inventoryItemId,
    'inventoryItemName': inventoryItemName,
    'quantity': quantity,
    'unit': unit,
    'unitCost': unitCost,
    'totalCost': totalCost,
    'reason': reason.name,
    'loggedByName': loggedByName,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
  };

  factory WasteLogEntity.fromJson(Map<String, dynamic> json) {
    final reasonStr = json['reason'] as String? ?? 'other';
    final reason = WasteReason.values.firstWhere(
      (r) => r.name == reasonStr,
      orElse: () => WasteReason.other,
    );

    return WasteLogEntity(
      id: json['id'] as String,
      inventoryItemId: json['inventoryItemId'] as String,
      inventoryItemName: json['inventoryItemName'] as String? ?? 'عنصر مخزون',
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String? ?? 'كغ',
      unitCost: (json['unitCost'] as num?)?.toDouble() ?? 0.0,
      totalCost: (json['totalCost'] as num?)?.toDouble() ?? 0.0,
      reason: reason,
      loggedByName: json['loggedByName'] as String? ?? 'المدير المسؤول',
      notes: json['notes'] as String?,
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
    );
  }
}
