import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/app_config.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/purchase_order_entity.dart';
import '../../domain/services/purchase_order_service.dart';

/// State holding all Purchase Orders for inventory management.
class PurchaseOrderState {
  const PurchaseOrderState({
    this.orders = const [],
    this.selectedStatusFilter,
  });

  final List<PurchaseOrderEntity> orders;
  final POStatus? selectedStatusFilter;

  List<PurchaseOrderEntity> get activePendingOrders =>
      orders.where((po) => po.status == POStatus.draft || po.status == POStatus.sentToSupplier).toList();

  List<PurchaseOrderEntity> get receivedOrders =>
      orders.where((po) => po.status == POStatus.received).toList();

  double get totalActualSpend => PurchaseOrderService.calculateTotalPurchasesCost(orders);

  List<PurchaseOrderEntity> get filteredOrders {
    if (selectedStatusFilter == null) return orders;
    return orders.where((o) => o.status == selectedStatusFilter).toList();
  }

  double get totalCommittedCost {
    return orders
        .where((o) => o.status != POStatus.cancelled)
        .fold(0.0, (sum, o) => sum + (o.status == POStatus.received ? o.totalActualCost : o.totalEstimatedCost));
  }

  PurchaseOrderState copyWith({
    List<PurchaseOrderEntity>? orders,
    POStatus? selectedStatusFilter,
  }) {
    return PurchaseOrderState(
      orders: orders ?? this.orders,
      selectedStatusFilter: selectedStatusFilter ?? this.selectedStatusFilter,
    );
  }
}

/// Controller managing Purchase Orders lifecycle (draft, send, receive into inventory).
class PurchaseOrderController extends StateNotifier<PurchaseOrderState> {
  PurchaseOrderController({SupabaseClient? supabase})
      : _supabase = supabase,
        super(
          const PurchaseOrderState(
            orders: [],
          ),
        ) {
    if (_supabase != null) {
      _loadFromSupabase();
    }
  }

  final SupabaseClient? _supabase;

  Future<void> _loadFromSupabase() async {
    final client = _supabase;
    if (client == null) return;
    try {
      final rows = await client
          .from('purchase_orders')
          .select()
          .order('order_date', ascending: false);

      if (rows.isNotEmpty) {
        final List<PurchaseOrderEntity> orders = [];
        for (final r in (rows as List)) {
          final m = Map<String, dynamic>.from(r as Map);
          final statusStr = m['status']?.toString() ?? 'draft';
          final status = POStatus.values.firstWhere(
            (val) => val.name == statusStr,
            orElse: () => POStatus.sentToSupplier,
          );

          final rawItems = m['items_json'] as List? ?? [];
          final List<POItem> items = [];
          for (final itm in rawItems) {
            final im = Map<String, dynamic>.from(itm as Map);
            items.add(
              POItem(
                ingredientId: im['ingredientId']?.toString() ?? '',
                ingredientName: im['ingredientName']?.toString() ?? '',
                unit: im['unit']?.toString() ?? 'كجم',
                orderedQuantity: (im['orderedQuantity'] as num?)?.toDouble() ?? 0.0,
                receivedQuantity: (im['receivedQuantity'] as num?)?.toDouble(),
                estimatedUnitPrice: (im['estimatedUnitPrice'] as num?)?.toDouble() ?? 0.0,
                actualUnitPrice: (im['actualUnitPrice'] as num?)?.toDouble(),
              ),
            );
          }

          orders.add(
            PurchaseOrderEntity(
              id: m['id']?.toString() ?? '',
              supplierName: m['supplier_name']?.toString() ?? '',
              supplierPhone: m['supplier_phone']?.toString() ?? '',
              orderDate: DateTime.tryParse(m['order_date']?.toString() ?? '') ?? DateTime.now(),
              expectedDeliveryDate: m['expected_delivery_date'] != null
                  ? DateTime.tryParse(m['expected_delivery_date'].toString())
                  : null,
              receivedAt: m['actual_delivery_date'] != null
                  ? DateTime.tryParse(m['actual_delivery_date'].toString())
                  : null,
              status: status,
              items: items,
              notes: m['notes']?.toString(),
            ),
          );
        }
        state = state.copyWith(orders: orders);
      }
    } catch (e) {
      AppLogger.warning('PurchaseOrderController loadFromSupabase error: $e');
    }
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

    final client = _supabase;
    if (client != null) {
      Future.microtask(() async {
        try {
          await client.from('purchase_orders').insert({
            'id': po.id,
            'restaurant_id': '1e08b47c-15be-4604-a913-431af7fbd54f',
            'supplier_name': po.supplierName,
            'supplier_phone': po.supplierPhone,
            'status': po.status.name,
            'order_date': po.orderDate.toIso8601String(),
            'expected_delivery_date': po.expectedDeliveryDate?.toIso8601String(),
            'items_json': po.items
                .map((i) => {
                      'ingredientId': i.ingredientId,
                      'ingredientName': i.ingredientName,
                      'unit': i.unit,
                      'orderedQuantity': i.orderedQuantity,
                      'estimatedUnitPrice': i.estimatedUnitPrice,
                    })
                .toList(),
            'total_amount': po.totalEstimatedCost,
            'notes': po.notes,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          AppLogger.warning('PurchaseOrder createPO sync error: $e');
        }
      });
    }

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

    final client = _supabase;
    if (client != null) {
      Future.microtask(() async {
        try {
          await client.from('purchase_orders').update({
            'status': updated.status.name,
            'actual_delivery_date': DateTime.now().toIso8601String(),
            'total_amount': updated.totalActualCost,
            'notes': updated.notes,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', poId);
        } catch (e) {
          AppLogger.warning('PurchaseOrder markReceived sync error: $e');
        }
      });
    }

    return updated;
  }
}

/// Riverpod provider for [PurchaseOrderController].
final purchaseOrderControllerProvider =
    StateNotifierProvider<PurchaseOrderController, PurchaseOrderState>((ref) {
      final supabase = AppConfig.useSupabase ? ref.watch(supabaseClientProvider) : null;
      return PurchaseOrderController(supabase: supabase);
    });
