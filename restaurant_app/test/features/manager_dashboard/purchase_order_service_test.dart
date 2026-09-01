import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/manager_dashboard/domain/entities/purchase_order_entity.dart';
import 'package:restaurant_app/features/manager_dashboard/domain/services/purchase_order_service.dart';

void main() {
  group('PurchaseOrderService Tests', () {
    test('Calculates estimated and actual cost and variances accurately', () {
      final po = PurchaseOrderEntity(
        id: 'PO-101',
        supplierName: 'شركة اللحوم',
        supplierPhone: '01012345678',
        orderDate: DateTime.now(),
        items: const [
          POItem(
            ingredientId: 'ing-meat',
            ingredientName: 'لحم بقري',
            unit: 'كجم',
            orderedQuantity: 20.0,
            estimatedUnitPrice: 300.0, // 6000 estimated
          ),
        ],
      );

      expect(po.totalEstimatedCost, 6000.0);
      expect(po.status, POStatus.draft);

      final receivedPO = PurchaseOrderService.markAsReceived(
        currentPO: po,
        supplierInvoiceNumber: 'INV-9901',
        receivedItems: const [
          POItem(
            ingredientId: 'ing-meat',
            ingredientName: 'لحم بقري',
            unit: 'كجم',
            orderedQuantity: 20.0,
            receivedQuantity: 22.0,
            estimatedUnitPrice: 300.0,
            actualUnitPrice: 310.0, // 22 * 310 = 6820.0
          ),
        ],
      );

      expect(receivedPO.status, POStatus.received);
      expect(receivedPO.supplierInvoiceNumber, 'INV-9901');
      expect(receivedPO.totalActualCost, 6820.0);
      expect(receivedPO.costVariance, 820.0);
      expect(PurchaseOrderService.hasPriceIncrease(receivedPO), isTrue);
    });

    test('Computes total spend across multiple received purchase orders', () {
      final orders = [
        PurchaseOrderEntity(
          id: 'PO-1',
          supplierName: 'س 1',
          supplierPhone: '0100',
          orderDate: DateTime.now(),
          status: POStatus.received,
          items: const [
            POItem(
              ingredientId: '1',
              ingredientName: 'دجاج',
              unit: 'كجم',
              orderedQuantity: 10,
              receivedQuantity: 10,
              estimatedUnitPrice: 100,
              actualUnitPrice: 100,
            ),
          ],
        ),
        PurchaseOrderEntity(
          id: 'PO-2',
          supplierName: 'س 2',
          supplierPhone: '0100',
          orderDate: DateTime.now(),
          status: POStatus.draft, // not received yet
          items: const [
            POItem(
              ingredientId: '2',
              ingredientName: 'جبنة',
              unit: 'كجم',
              orderedQuantity: 5,
              estimatedUnitPrice: 200,
            ),
          ],
        ),
      ];

      final totalSpend = PurchaseOrderService.calculateTotalPurchasesCost(orders);
      expect(totalSpend, 1000.0);
    });
  });
}
