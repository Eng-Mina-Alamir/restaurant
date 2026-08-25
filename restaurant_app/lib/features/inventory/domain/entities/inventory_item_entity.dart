/// Stock level status for an inventory item.
enum StockStatus {
  sufficient, // كافٍ
  low, // منخفض
  outOfStock, // منتهي
}

/// Domain entity representing a tracked restaurant inventory item.
class InventoryItemEntity {
  const InventoryItemEntity({
    required this.id,
    required this.name,
    required this.category,
    required this.currentStock,
    required this.unit,
    required this.minThreshold,
    required this.costPerUnit,
  });

  final String id;
  final String name;
  final String category;
  final double currentStock;
  final String unit;
  final double minThreshold;
  final double costPerUnit;

  StockStatus get status {
    if (currentStock <= 0) return StockStatus.outOfStock;
    if (currentStock <= minThreshold) return StockStatus.low;
    return StockStatus.sufficient;
  }

  String get statusLabel {
    switch (status) {
      case StockStatus.sufficient:
        return 'كافٍ';
      case StockStatus.low:
        return 'منخفض';
      case StockStatus.outOfStock:
        return 'منتهي';
    }
  }

  double get totalValue => currentStock * costPerUnit;

  InventoryItemEntity copyWith({
    String? id,
    String? name,
    String? category,
    double? currentStock,
    String? unit,
    double? minThreshold,
    double? costPerUnit,
  }) {
    return InventoryItemEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      currentStock: currentStock ?? this.currentStock,
      unit: unit ?? this.unit,
      minThreshold: minThreshold ?? this.minThreshold,
      costPerUnit: costPerUnit ?? this.costPerUnit,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'currentStock': currentStock,
    'unit': unit,
    'minThreshold': minThreshold,
    'costPerUnit': costPerUnit,
  };

  factory InventoryItemEntity.fromJson(Map<String, dynamic> json) {
    return InventoryItemEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      currentStock: (json['currentStock'] as num).toDouble(),
      unit: json['unit'] as String,
      minThreshold: (json['minThreshold'] as num).toDouble(),
      costPerUnit: (json['costPerUnit'] as num).toDouble(),
    );
  }
}
