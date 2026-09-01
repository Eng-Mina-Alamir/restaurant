import '../entities/purchase_order_entity.dart';

/// Pure domain service calculating purchase order costs, receiving quantities, and price variances.
abstract final class PurchaseOrderService {
  PurchaseOrderService._();

  /// Calculates total monetary volume across all purchase orders.
  static double calculateTotalPurchasesCost(List<PurchaseOrderEntity> orders) {
    return orders
        .where((po) => po.status == POStatus.received)
        .fold<double>(0.0, (acc, po) => acc + po.totalActualCost);
  }

  /// Verifies if a purchase order has price variance upon receiving from supplier.
  static bool hasPriceIncrease(PurchaseOrderEntity po) {
    return po.totalActualCost > po.totalEstimatedCost;
  }

  /// Marks a purchase order as received with actual supplier quantities and invoice number.
  static PurchaseOrderEntity markAsReceived({
    required PurchaseOrderEntity currentPO,
    required String supplierInvoiceNumber,
    required List<POItem> receivedItems,
    String? notes,
  }) {
    return currentPO.copyWith(
      status: POStatus.received,
      receivedAt: DateTime.now(),
      supplierInvoiceNumber: supplierInvoiceNumber,
      items: receivedItems,
      notes: notes ?? currentPO.notes,
    );
  }
}
