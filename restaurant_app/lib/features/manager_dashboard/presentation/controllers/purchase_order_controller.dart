import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/service_locator.dart';
import '../../data/repositories/supabase_manager_operations_repository.dart';
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
  PurchaseOrderController([this._repository]) : super(const PurchaseOrderState()) {
    loadOrders();
  }

  final SupabaseManagerOperationsRepository? _repository;

  Future<void> loadOrders() async {
    if (_repository == null) return;
    final result = await _repository.getPurchaseOrders();
    result.when(
      onLeft: (_) {},
      onRight: (pos) {
        if (mounted) state = state.copyWith(orders: pos);
      },
    );
  }

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
    _repository?.savePurchaseOrder(po);
    return po;
  }

  /// Updates status of a PO.
  void updatePOStatus(String poId, POStatus newStatus) {
    final updated = state.orders.map((po) {
      if (po.id == poId) {
        final mod = po.copyWith(status: newStatus);
        _repository?.savePurchaseOrder(mod);
        return mod;
      }
      return po;
    }).toList();

    state = state.copyWith(orders: updated);
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
    _repository?.savePurchaseOrder(updated);
    return updated;
  }

  /// Receives items against a purchase order.
  void receivePO({
    required String poId,
    required String invoiceNumber,
    required List<POItem> receivedItems,
  }) {
    markReceived(
      poId: poId,
      supplierInvoiceNumber: invoiceNumber,
      receivedItems: receivedItems,
    );
  }
}

/// Riverpod provider for [PurchaseOrderController].
final purchaseOrderControllerProvider =
    StateNotifierProvider<PurchaseOrderController, PurchaseOrderState>((ref) {
      final repo = ref.watch(supabaseManagerOperationsRepositoryProvider);
      return PurchaseOrderController(repo);
    });
