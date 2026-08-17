import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/enums.dart';
import '../../../../core/utils/formatters.dart';
import '../../../orders/domain/entities/order_entity.dart';

/// Service responsible for generating exportable reports (CSV, structured ZATCA receipts).
class ReportExportService {
  const ReportExportService();

  /// Generates UTF-8 CSV content with BOM for completed invoices list.
  String generateInvoicesCsv(List<OrderEntity> orders) {
    final buffer = StringBuffer();
    // UTF-8 BOM for Arabic support in Excel
    buffer.write('\uFEFF');
    buffer.writeln(
      'رقم الفاتورة,التاريخ والوقت,نوع الطلب,عدد الأصناف,المجموع الفرعي,الضريبة 15%,الخصم,الإجمالي,الحالة',
    );

    for (final order in orders) {
      final typeStr = _orderTypeLabel(order.orderType);
      final dateStr = Formatters.formatDateTime(order.createdAt).replaceAll(',', ' ');
      final subtotal = order.subtotal.toStringAsFixed(2);
      final tax = order.taxAmount.toStringAsFixed(2);
      final discount = order.discountAmount.toStringAsFixed(2);
      final total = order.totalAmount.toStringAsFixed(2);

      buffer.writeln(
        '${order.id},"$dateStr",$typeStr,${order.items.length},$subtotal,$tax,$discount,$total,مكتمل',
      );
    }

    return buffer.toString();
  }

  /// Generates a structured ZATCA (الهيئة العامة للزكاة والضريبة والجمارك) compliant text receipt.
  String generateZatcaReceiptText(
    OrderEntity order, {
    String restaurantName = 'مطعم الذواقة الأصيل',
    String vatNumber = '300012345600003',
  }) {
    final buffer = StringBuffer();
    final dateStr = Formatters.formatDateTime(order.createdAt);

    buffer.writeln('====================================');
    buffer.writeln('       فاتورة ضريبية مبسطة          ');
    buffer.writeln('      SIMPLIFIED TAX INVOICE        ');
    buffer.writeln('====================================');
    buffer.writeln('المنشأة: $restaurantName');
    buffer.writeln('الرقم الضريبي: $vatNumber');
    buffer.writeln('رقم الفاتورة: ${order.id}');
    buffer.writeln('التاريخ: $dateStr');
    buffer.writeln('نوع الطلب: ${_orderTypeLabel(order.orderType)}');
    if (order.tableId != null) {
      buffer.writeln('الطاولة: ${order.tableId}');
    }
    buffer.writeln('------------------------------------');
    buffer.writeln('الصنف              الكمية     السعر');
    buffer.writeln('------------------------------------');

    for (final item in order.items) {
      final name = item.menuItem.name.padRight(16);
      final qty = '${item.quantity}x'.padRight(8);
      final total = Formatters.formatCurrency(item.lineTotal);
      buffer.writeln('$name $qty $total');
    }

    buffer.writeln('------------------------------------');
    buffer.writeln('المجموع الخاضع للضريبة: ${Formatters.formatCurrency(order.subtotal)}');
    buffer.writeln('ضريبة القيمة المضافة 15%: ${Formatters.formatCurrency(order.taxAmount)}');
    if (order.discountAmount > 0) {
      buffer.writeln('الخصم: -${Formatters.formatCurrency(order.discountAmount)}');
    }
    buffer.writeln('------------------------------------');
    buffer.writeln('المجموع الكلي: ${Formatters.formatCurrency(order.totalAmount)}');
    buffer.writeln('====================================');
    buffer.writeln('        شكراً لزيارتكم              ');
    buffer.writeln('====================================');

    return buffer.toString();
  }

  String _orderTypeLabel(OrderType type) {
    switch (type) {
      case OrderType.dineIn:
        return 'محلي / داخلي';
      case OrderType.takeaway:
        return 'سفري / استلام';
      case OrderType.delivery:
        return 'توصيل';
    }
  }
}

final reportExportServiceProvider = Provider<ReportExportService>((ref) {
  return const ReportExportService();
});
