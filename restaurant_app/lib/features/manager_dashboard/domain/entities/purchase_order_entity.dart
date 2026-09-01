enum POStatus {
  draft('مسودة جديدة 📝'),
  sentToSupplier('مرسل للمورد 🚚'),
  received('تم الفحص والاستلام بالمخزن ✅'),
  cancelled('ملغي ❌');

  final String labelAr;
  const POStatus(this.labelAr);
}

/// A line item in a supplier Purchase Order.
class POItem {
  const POItem({
    required this.ingredientId,
    required this.ingredientName,
    required this.unit,
    required this.orderedQuantity,
    this.receivedQuantity,
    required this.estimatedUnitPrice,
    this.actualUnitPrice,
  });

  final String ingredientId;
  final String ingredientName;
  final String unit; // kg, liter, piece, etc.
  final double orderedQuantity;
  final double? receivedQuantity;
  final double estimatedUnitPrice;
  final double? actualUnitPrice;

  double get estimatedLineTotal => orderedQuantity * estimatedUnitPrice;

  double get actualLineTotal => (receivedQuantity ?? orderedQuantity) * (actualUnitPrice ?? estimatedUnitPrice);

  POItem copyWith({
    String? ingredientId,
    String? ingredientName,
    String? unit,
    double? orderedQuantity,
    double? receivedQuantity,
    double? estimatedUnitPrice,
    double? actualUnitPrice,
  }) {
    return POItem(
      ingredientId: ingredientId ?? this.ingredientId,
      ingredientName: ingredientName ?? this.ingredientName,
      unit: unit ?? this.unit,
      orderedQuantity: orderedQuantity ?? this.orderedQuantity,
      receivedQuantity: receivedQuantity ?? this.receivedQuantity,
      estimatedUnitPrice: estimatedUnitPrice ?? this.estimatedUnitPrice,
      actualUnitPrice: actualUnitPrice ?? this.actualUnitPrice,
    );
  }
}

/// A formal Purchase Order (PO) issued to food & beverage raw ingredient suppliers.
class PurchaseOrderEntity {
  const PurchaseOrderEntity({
    required this.id,
    required this.supplierName,
    required this.supplierPhone,
    required this.orderDate,
    this.expectedDeliveryDate,
    this.receivedAt,
    required this.items,
    this.status = POStatus.draft,
    this.supplierInvoiceNumber,
    this.notes,
    this.authorizedByManagerName,
  });

  final String id;
  final String supplierName;
  final String supplierPhone;
  final DateTime orderDate;
  final DateTime? expectedDeliveryDate;
  final DateTime? receivedAt;
  final List<POItem> items;
  final POStatus status;
  final String? supplierInvoiceNumber;
  final String? notes;
  final String? authorizedByManagerName;

  double get totalEstimatedCost => items.fold<double>(0.0, (acc, it) => acc + it.estimatedLineTotal);

  double get totalActualCost => items.fold<double>(0.0, (acc, it) => acc + it.actualLineTotal);

  double get costVariance => totalActualCost - totalEstimatedCost;

  PurchaseOrderEntity copyWith({
    String? id,
    String? supplierName,
    String? supplierPhone,
    DateTime? orderDate,
    DateTime? expectedDeliveryDate,
    DateTime? receivedAt,
    List<POItem>? items,
    POStatus? status,
    String? supplierInvoiceNumber,
    String? notes,
    String? authorizedByManagerName,
  }) {
    return PurchaseOrderEntity(
      id: id ?? this.id,
      supplierName: supplierName ?? this.supplierName,
      supplierPhone: supplierPhone ?? this.supplierPhone,
      orderDate: orderDate ?? this.orderDate,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      receivedAt: receivedAt ?? this.receivedAt,
      items: items ?? this.items,
      status: status ?? this.status,
      supplierInvoiceNumber: supplierInvoiceNumber ?? this.supplierInvoiceNumber,
      notes: notes ?? this.notes,
      authorizedByManagerName: authorizedByManagerName ?? this.authorizedByManagerName,
    );
  }
}
