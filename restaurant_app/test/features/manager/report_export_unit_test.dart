import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/inventory/domain/entities/inventory_item_entity.dart';
import 'package:restaurant_app/features/manager_dashboard/data/services/report_export_service.dart';
import 'package:restaurant_app/features/manager_dashboard/domain/entities/financial_report_entity.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_entity.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_item.dart';

void main() {
  group('ReportExportService Unit Tests', () {
    const service = ReportExportService();

    final testOrder = OrderEntity(
      id: 'ORD-777',
      restaurantId: 'rest-1',
      tableId: 'tbl-4',
      orderType: OrderType.dineIn,
      status: OrderStatus.completed,
      items: [
        OrderItem(
          menuItem: const MenuItem(
            id: 'i1',
            categoryId: 'c1',
            name: 'مشويات مشكلة',
            description: '',
            price: 100.0,
          ),
          quantity: 2,
          itemTotal: 200.0,
          addedAt: DateTime(2026, 8, 19, 13, 0),
        ),
      ],
      subtotal: 200.0,
      taxAmount: 30.0,
      discountAmount: 10.0,
      totalAmount: 220.0,
      createdAt: DateTime(2026, 8, 19, 13, 0),
    );

    test('generateInvoicesCsv outputs UTF-8 BOM, headers, and order rows', () {
      final csv = service.generateInvoicesCsv([testOrder]);

      expect(csv.startsWith('\uFEFF'), isTrue);
      expect(csv, contains('رقم الفاتورة'));
      expect(csv, contains('ORD-777'));
      expect(csv, contains('200.00'));
      expect(csv, contains('220.00'));
    });

    test('generateInventoryCsv formats inventory list into CSV', () {
      const item = InventoryItemEntity(
        id: 'inv-1',
        name: 'لحم ضأن',
        category: 'لحوم',
        currentStock: 25.0,
        minThreshold: 10.0,
        unit: 'كجم',
        costPerUnit: 250.0,
      );

      final csv = service.generateInventoryCsv([item]);

      expect(csv.startsWith('\uFEFF'), isTrue);
      expect(csv, contains('معرف الصنف'));
      expect(csv, contains('لحم ضأن'));
      expect(csv, contains('250'));
    });

    test('generateFinancialReportCsv includes P&L lines and top profitable items', () {
      const metrics = FinancialReportMetrics(
        grossRevenue: 10000.0,
        cogs: 4000.0,
        operatingCosts: 2000.0,
        netProfit: 4000.0,
        grossMarginPercentage: 60.0,
        netMarginPercentage: 40.0,
        averageOrderValue: 200.0,
        totalOrders: 50,
        completedOrders: 48,
        cancelledOrders: 2,
        paymentBreakdown: {'نقداً': 5000.0, 'بطاقة': 5000.0},
        topProfitableItems: [
          ItemProfitability(
            itemName: 'مشويات',
            unitsSold: 30,
            revenue: 6000.0,
            estimatedCost: 2000.0,
            profit: 4000.0,
            marginPercent: 66.7,
          ),
        ],
      );

      final csv = service.generateFinancialReportCsv(metrics, 'أغسطس 2026');

      expect(csv, contains('بيان الأرباح والخسائر'));
      expect(csv, contains('10000.00'));
      expect(csv, contains('مشويات'));
      expect(csv, contains('66.7%'));
    });

    test('generateZatcaReceiptText formats tax invoice text accurately', () {
      final receipt = service.generateZatcaReceiptText(testOrder);

      expect(receipt, contains('فاتورة ضريبية مبسطة'));
      expect(receipt, contains('ORD-777'));
      expect(receipt, contains('الطاولة: tbl-4'));
      expect(receipt, contains('مشويات مشكلة'));
      expect(receipt, contains('المجموع الكلي'));
    });
  });
}
