import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/inventory/domain/entities/inventory_item_entity.dart';
import 'package:restaurant_app/features/manager_dashboard/data/services/report_export_service.dart';
import 'package:restaurant_app/features/manager_dashboard/domain/entities/financial_report_entity.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_entity.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_item.dart';

void main() {
  group('ReportExportService', () {
    const service = ReportExportService();

    final testItem = OrderItem(
      menuItem: const MenuItem(
        id: 'M-1',
        name: 'برجر كلاسيك',
        description: 'برجر لحم مع جبنة',
        price: 35.0,
        imageUrl: '',
        categoryId: 'البرجر',
      ),
      quantity: 2,
      addedAt: DateTime(2026, 8, 18, 14, 30),
    );

    final testOrder = OrderEntity(
      id: 'ORD-789',
      restaurantId: 'rest-1',
      orderType: OrderType.dineIn,
      tableId: '5',
      items: [testItem],
      status: OrderStatus.completed,
      createdAt: DateTime(2026, 8, 18, 14, 30),
      discountAmount: 5.0,
      subtotal: 70.0,
      taxAmount: 10.5,
      totalAmount: 75.5,
    );

    test('generateInvoicesCsv generates CSV with BOM and columns', () {
      final csv = service.generateInvoicesCsv([testOrder]);

      expect(csv.startsWith('\uFEFF'), isTrue);
      expect(csv, contains('رقم الفاتورة,التاريخ والوقت,نوع الطلب'));
      expect(csv, contains('ORD-789'));
      expect(csv, contains('محلي / داخلي'));
      expect(csv, contains('مكتمل'));
    });

    test('generateInventoryCsv exports inventory columns and values', () {
      final items = [
        const InventoryItemEntity(
          id: 'inv-1',
          name: 'لحم بقري',
          category: 'لحوم',
          currentStock: 15.0,
          unit: 'كغ',
          minThreshold: 5.0,
          costPerUnit: 50.0,
        ),
      ];

      final csv = service.generateInventoryCsv(items);
      expect(csv.startsWith('\uFEFF'), isTrue);
      expect(csv, contains('معرف الصنف,اسم الصنف,الفئة,الكمية الحالية'));
      expect(csv, contains('لحم بقري'));
      expect(csv, contains('750.00'));
    });

    test('generateFinancialReportCsv exports P&L statement summary', () {
      const metrics = FinancialReportMetrics(
        grossRevenue: 10000.0,
        cogs: 3000.0,
        operatingCosts: 2500.0,
        netProfit: 4500.0,
        grossMarginPercentage: 70.0,
        netMarginPercentage: 45.0,
        averageOrderValue: 100.0,
        totalOrders: 100,
        completedOrders: 100,
        cancelledOrders: 0,
        paymentBreakdown: {'cash': 5000.0, 'card': 5000.0},
        topProfitableItems: [
          ItemProfitability(
            itemName: 'برجر ترفل',
            unitsSold: 50,
            revenue: 2500.0,
            estimatedCost: 500.0,
            profit: 2000.0,
            marginPercent: 80.0,
          ),
        ],
      );

      final csv = service.generateFinancialReportCsv(metrics, 'هذا الشهر');
      expect(csv.startsWith('\uFEFF'), isTrue);
      expect(csv, contains('بيان الأرباح والخسائر والتحليل المالي - هذا الشهر'));
      expect(csv, contains('إجمالي الإيرادات والمبيعات,10000.00'));
      expect(csv, contains('صافي الربح التشغيلي (Net Income),4500.00'));
      expect(csv, contains('برجر ترفل'));
    });

    test('generateZatcaReceiptText includes required ZATCA tax invoice headers', () {
      final receipt = service.generateZatcaReceiptText(testOrder);

      expect(receipt, contains('فاتورة ضريبية مبسطة'));
      expect(receipt, contains('SIMPLIFIED TAX INVOICE'));
      expect(receipt, contains('الرقم الضريبي'));
      expect(receipt, contains('ORD-789'));
      expect(receipt, contains('برجر كلاسيك'));
      expect(receipt, contains('2x'));
      expect(receipt, contains('ضريبة القيمة المضافة 15%'));
      expect(receipt, contains('شكراً لزيارتكم'));
    });
  });
}
