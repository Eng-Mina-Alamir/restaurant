import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/purchase_order_entity.dart';
import '../../domain/services/purchase_order_service.dart';

/// State of all supplier purchase orders.
class PurchaseOrderState {
  const PurchaseOrderState({
    this.orders = const [],
  });

  final List<PurchaseOrderEntity> orders;

  List<PurchaseOrderEntity> get activePendingOrders =>
      orders.where((po) => po.status == POStatus.draft || po.status == POStatus.sentToSupplier).toList();

  List<PurchaseOrderEntity> get receivedOrders =>
      orders.where((po) => po.status == POStatus.received).toList();

  double get totalActualSpend => PurchaseOrderService.calculateTotalPurchasesCost(orders);

  PurchaseOrderState copyWith({
    List<PurchaseOrderEntity>? orders,
  }) {
    return PurchaseOrderState(
      orders: orders ?? this.orders,
    );
  }
}

/// Controller managing Purchase Orders lifecycle (draft, send, receive into inventory).
class PurchaseOrderController extends StateNotifier<PurchaseOrderState> {
  PurchaseOrderController()
      : super(
          PurchaseOrderState(
            orders: [
              PurchaseOrderEntity(
                id: 'PO-101',
                supplierName: 'شركة الأهرام للحوم والدواجن الطازجة',
                supplierPhone: '01012345678',
                orderDate: DateTime.now().subtract(const Duration(days: 1)),
                expectedDeliveryDate: DateTime.now(),
                status: POStatus.sentToSupplier,
                items: const [
                  POItem(
                    ingredientId: 'ing-chicken',
                    ingredientName: 'صدور دجاج طازجة متبلة',
                    unit: 'كجم',
                    orderedQuantity: 50.0,
                    estimatedUnitPrice: 180.0,
                  ),
                  POItem(
                    ingredientId: 'ing-beef',
                    ingredientName: 'لحم بقري برجر بلدي',
                    unit: 'كجم',
                    orderedQuantity: 30.0,
                    estimatedUnitPrice: 320.0,
                  ),
                ],
              ),
              PurchaseOrderEntity(
                id: 'PO-100',
                supplierName: 'مزارع النيل للخضار والصلصات',
                supplierPhone: '01122334455',
                orderDate: DateTime.now().subtract(const Duration(days: 3)),
                receivedAt: DateTime.now().subtract(const Duration(days: 2)),
                status: POStatus.received,
                supplierInvoiceNumber: 'INV-54129',
                items: const [
                  POItem(
                    ingredientId: 'ing-tomato',
                    ingredientName: 'طماطم وخضروات طازجة',
                    unit: 'كجم',
                    orderedQuantity: 40.0,
                    receivedQuantity: 40.0,
                    estimatedUnitPrice: 25.0,
                    actualUnitPrice: 25.0,
                  ),
                ],
              ),
            ],
          ),
        );

  /// Creates a new Purchase Order.
  PurchaseOrderEntity createPO({
    required String supplierName,
    required String supplierPhone,
    required List<POItem> items,
    DateTime? expectedDeliveryDate,
    String? notes,
  }) {
    final po = PurchaseOrderEntity(
      id: 'PO-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      supplierName: supplierName,
      supplierPhone: supplierPhone,
      orderDate: DateTime.now(),
      expectedDeliveryDate: expectedDeliveryDate ?? DateTime.now().add(const Duration(days: 1)),
      items: items,
      status: POStatus.sentToSupplier,
      notes: notes,
    );

    state = state.copyWith(orders: [po, ...state.orders]);
    return po;
  }

  /// Marks a PO as received, records invoice number, and final costs.
  PurchaseOrderEntity markReceived({
    required String poId,
    required String supplierInvoiceNumber,
    required List<POItem> receivedItems,
    String? notes,
  }) {
    final index = state.orders.indexWhere((o) => o.id == poId);
    if (index == -1) throw Exception('Purchase order not found');

    final updated = PurchaseOrderService.markAsReceived(
      currentPO: state.orders[index],
      supplierInvoiceNumber: supplierInvoiceNumber,
      receivedItems: receivedItems,
      notes: notes,
    );

    final list = [...state.orders]..[index] = updated;
    state = state.copyWith(orders: list);
    return updated;
  }
}

/// Riverpod provider for [PurchaseOrderController].
final purchaseOrderControllerProvider =
    StateNotifierProvider<PurchaseOrderController, PurchaseOrderState>((ref) {
      return PurchaseOrderController();
    });
