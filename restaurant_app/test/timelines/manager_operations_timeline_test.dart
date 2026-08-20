import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/coupons/domain/entities/coupon_entity.dart';
import 'package:restaurant_app/features/inventory/domain/entities/inventory_item_entity.dart';
import 'package:restaurant_app/features/manager_dashboard/data/services/report_export_service.dart';
import 'package:restaurant_app/features/manager_dashboard/domain/entities/financial_report_entity.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_entity.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_item.dart';

void main() {
  group('Timeline 7: Manager & Operations Full Journey Test', () {
    const sampleItem = MenuItem(
      id: 'mgr-item-1',
      categoryId: 'cat-main',
      name: 'طبق ستيك ريب آي فاخر',
      description: 'قطعة لحم ريب آي مع الخضار المشوية وصوص الفطر',
      price: 135.0,
      isAvailable: true,
    );

    test('Manager Operations Timeline: Live KPIs -> Update Menu -> Low Stock Audit -> Create Promo -> Export Financial Reports (CSV)', () async {
      const exportService = ReportExportService();

      // ── Step 1: Manager inspects daily orders & gross revenue ──────────────
      final completedOrder1 = OrderEntity(
        id: 'ORD-MGR-01',
        restaurantId: 'rest-1',
        tableId: 'TBL-1',
        customerId: 'CUST-10',
        orderType: OrderType.dineIn,
        status: OrderStatus.completed,
        items: [
          OrderItem(
            menuItem: sampleItem,
            quantity: 2,
            selectedModifiers: const [],
            addedAt: DateTime.now(),
          ),
        ],
        subtotal: 270.0,
        taxAmount: 40.5,
        totalAmount: 310.5,
        createdAt: DateTime.now(),
      );

      final completedOrder2 = OrderEntity(
        id: 'ORD-MGR-02',
        restaurantId: 'rest-1',
        tableId: null,
        customerId: 'CUST-11',
        orderType: OrderType.delivery,
        status: OrderStatus.completed,
        items: [
          OrderItem(
            menuItem: sampleItem,
            quantity: 1,
            selectedModifiers: const [],
            addedAt: DateTime.now(),
          ),
        ],
        subtotal: 135.0,
        taxAmount: 20.25,
        totalAmount: 155.25,
        createdAt: DateTime.now(),
      );

      final dailyOrders = [completedOrder1, completedOrder2];
      final grossRevenue = dailyOrders.fold<double>(0, (sum, o) => sum + o.totalAmount);
      expect(grossRevenue, equals(465.75));

      // ── Step 2: Manager modifies menu price and toggles availability ───────
      final updatedMenuItem = sampleItem.copyWith(
        price: 145.0, // price update
        isAvailable: false, // out of stock temporarily
      );

      expect(updatedMenuItem.price, equals(145.0));
      expect(updatedMenuItem.isAvailable, isFalse);

      // ── Step 3: Manager audits inventory levels and identifies low stock ───
      const beefInventory = InventoryItemEntity(
        id: 'inv-beef-01',
        name: 'لحم أنجوس مبرد',
        category: 'اللحوم',
        currentStock: 4.5,
        minThreshold: 10.0,
        unit: 'كجم',
        costPerUnit: 70.0,
      );

      expect(beefInventory.status, equals(StockStatus.low));

      // Restock action
      final restockedBeef = beefInventory.copyWith(currentStock: 25.0);
      expect(restockedBeef.status, equals(StockStatus.sufficient));

      // ── Step 4: Manager creates promotional coupon for weekend rush ────────
      const weekendPromo = CouponEntity(
        id: 'cpn-wknd-01',
        code: 'WEEKEND30',
        title: 'خصم الويكند 30 ريال',
        discountType: CouponDiscountType.fixed,
        discountValue: 30.0,
        minOrderAmount: 150.0,
      );

      expect(weekendPromo.calculateDiscount(200.0), equals(30.0));
      expect(weekendPromo.calculateDiscount(100.0), equals(0.0)); // under min spend

      // ── Step 5: Export CSV invoices & Financial Reports ───────────────────
      final invoicesCsv = exportService.generateInvoicesCsv(dailyOrders);
      expect(invoicesCsv, contains('\uFEFF')); // UTF-8 BOM
      expect(invoicesCsv, contains('ORD-MGR-01'));
      expect(invoicesCsv, contains('ORD-MGR-02'));
      expect(invoicesCsv, contains('310.50'));

      final inventoryCsv = exportService.generateInventoryCsv([beefInventory, restockedBeef]);
      expect(inventoryCsv, contains('لحم أنجوس مبرد'));

      const financialMetrics = FinancialReportMetrics(
        grossRevenue: 465.75,
        cogs: 180.0,
        operatingCosts: 90.0,
        netProfit: 195.75,
        grossMarginPercentage: 61.35,
        netMarginPercentage: 42.03,
        averageOrderValue: 232.88,
        totalOrders: 2,
        completedOrders: 2,
        cancelledOrders: 0,
        paymentBreakdown: {'card': 465.75},
        topProfitableItems: [
          ItemProfitability(
            itemName: 'طبق ستيك ريب آي فاخر',
            unitsSold: 3,
            revenue: 405.0,
            estimatedCost: 180.0,
            profit: 225.0,
            marginPercent: 55.5,
          ),
        ],
      );

      final financeCsv = exportService.generateFinancialReportCsv(financialMetrics, 'اليومي');
      expect(financeCsv, contains('إجمالي الإيرادات والمبيعات'));
      expect(financeCsv, contains('465.75'));
    });
  });
}
