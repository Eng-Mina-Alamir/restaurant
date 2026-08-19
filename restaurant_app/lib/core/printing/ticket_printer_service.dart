import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/formatters.dart';

import '../../features/orders/domain/entities/order_entity.dart';

/// Service responsible for generating ESC/POS thermal printer commands
/// and formatted printable kitchen tickets.
class TicketPrinterService {
  /// Generates plain-text thermal ticket receipt.
  String generateTicketText(OrderEntity order, {String? tableDisplay}) {
    final buffer = StringBuffer();
    const line = '--------------------------------';
    const doubleLine = '================================';

    buffer.writeln(doubleLine);
    buffer.writeln('       مطعم الأصالة والنكهة       ');
    buffer.writeln('    تذكرة المطبخ / Kitchen Ticket  ');
    buffer.writeln(doubleLine);
    buffer.writeln('رقم الطلب: ${Formatters.formatOrderId(order.id)}');
    buffer.writeln('الوقت: ${Formatters.formatDateTime(order.createdAt)}');

    if (tableDisplay != null) {
      buffer.writeln('الموقع: طاولة $tableDisplay');
    } else {
      buffer.writeln('نوع الطلب: ${order.orderType.name}');
    }

    if (order.customerId != null) {
      buffer.writeln('العميل: ${order.customerId}');
    }

    buffer.writeln(line);
    buffer.writeln('الكمية   الصنف                  ');
    buffer.writeln(line);

    for (final item in order.items) {
      final name = item.menuItem.name;
      buffer.writeln('${item.quantity.toString().padRight(4)} x  $name');

      if (item.selectedModifiers.isNotEmpty) {
        final mods = item.selectedModifiers.map((m) => m.name).join(', ');
        buffer.writeln('      + إضافات: $mods');
      }

      if (item.specialNotes != null && item.specialNotes!.trim().isNotEmpty) {
        buffer.writeln('      * ملاحظة: ${item.specialNotes}');
      }
    }

    buffer.writeln(line);
    final totalUnits = order.items.fold<int>(0, (s, i) => s + i.quantity);
    buffer.writeln('إجمالي الأصناف: $totalUnits عنصر');
    buffer.writeln('المبلغ الإجمالي: ${Formatters.formatCurrency(order.totalAmount)}');
    buffer.writeln(doubleLine);
    buffer.writeln('        يرجى التحضير فوراً       ');
    buffer.writeln(doubleLine);

    return buffer.toString();
  }

  /// Generates standard ESC/POS binary byte stream for thermal receipt printers.
  List<int> generateEscPosBytes(OrderEntity order, {String? tableDisplay}) {
    final bytes = <int>[];

    // Initialize printer: ESC @ (0x1B, 0x40)
    bytes.addAll([0x1B, 0x40]);

    // Center alignment: ESC a 1 (0x1B, 0x61, 0x01)
    bytes.addAll([0x1B, 0x61, 0x01]);

    // Bold ON: ESC E 1 (0x1B, 0x45, 0x01)
    bytes.addAll([0x1B, 0x45, 0x01]);
    bytes.addAll(utf8.encode('مطعم الأصالة والنكهة\n'));
    bytes.addAll(utf8.encode('تذكرة تحضير المطبخ\n'));
    bytes.addAll([0x1B, 0x45, 0x00]); // Bold OFF

    // Left alignment: ESC a 0 (0x1B, 0x61, 0x00)
    bytes.addAll([0x1B, 0x61, 0x00]);
    bytes.addAll(utf8.encode('--------------------------------\n'));
    bytes.addAll(utf8.encode('رقم الطلب: ${Formatters.formatOrderId(order.id)}\n'));
    bytes.addAll(utf8.encode('الوقت: ${Formatters.formatDateTime(order.createdAt)}\n'));
    if (tableDisplay != null) {
      bytes.addAll(utf8.encode('الموقع: طاولة $tableDisplay\n'));
    }
    bytes.addAll(utf8.encode('--------------------------------\n'));

    // Items
    for (final item in order.items) {
      bytes.addAll([0x1B, 0x45, 0x01]); // Bold
      bytes.addAll(utf8.encode('${item.quantity} x ${item.menuItem.name}\n'));
      bytes.addAll([0x1B, 0x45, 0x00]); // Normal

      if (item.selectedModifiers.isNotEmpty) {
        final mods = item.selectedModifiers.map((m) => m.name).join(', ');
        bytes.addAll(utf8.encode('   + $mods\n'));
      }
      if (item.specialNotes != null && item.specialNotes!.trim().isNotEmpty) {
        bytes.addAll(utf8.encode('   * ملاحظات: ${item.specialNotes}\n'));
      }
    }

    bytes.addAll(utf8.encode('================================\n'));

    // Center alignment for barcode & footer
    bytes.addAll([0x1B, 0x61, 0x01]);
    bytes.addAll(utf8.encode('الإجمالي: ${Formatters.formatCurrency(order.totalAmount)}\n'));
    bytes.addAll(utf8.encode('شكراً لكم\n\n\n'));

    // Cut paper command: GS V 66 0 (0x1D, 0x56, 0x42, 0x00)
    bytes.addAll([0x1D, 0x56, 0x42, 0x00]);

    return bytes;
  }

  /// Dispatches the print job to connected thermal printer (simulated network/USB printer).
  Future<bool> printKitchenTicket(OrderEntity order, {String? tableDisplay}) async {
    // Simulate printer hardware handshake
    await Future.delayed(const Duration(milliseconds: 600));
    return true;
  }
}

final ticketPrinterServiceProvider = Provider<TicketPrinterService>((ref) {
  return TicketPrinterService();
});
