import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/manager_dashboard/data/services/report_export_service.dart';
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
