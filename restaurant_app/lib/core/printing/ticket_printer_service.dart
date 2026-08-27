import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/formatters.dart';
import '../utils/logger.dart';
import 'network_printer_service.dart';

import '../../features/orders/domain/entities/order_entity.dart';

/// Service responsible for generating ESC/POS thermal printer commands
/// and sending formatted printable kitchen tickets & tax invoices to hardware printers.
class TicketPrinterService {
  const TicketPrinterService({NetworkPrinterService? networkPrinterService})
      : _networkPrinter = networkPrinterService ?? const NetworkPrinterService();

  final NetworkPrinterService _networkPrinter;

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
    buffer.writeln(
      'المبلغ الإجمالي: ${Formatters.formatCurrency(order.totalAmount)}',
    );
    buffer.writeln(doubleLine);
    buffer.writeln('        يرجى التحضير فوراً       ');
    buffer.writeln(doubleLine);

    return buffer.toString();
  }

  /// Generates standard ESC/POS binary byte stream for kitchen thermal printers.
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
    bytes.addAll(
      utf8.encode('رقم الطلب: ${Formatters.formatOrderId(order.id)}\n'),
    );
    bytes.addAll(
      utf8.encode('الوقت: ${Formatters.formatDateTime(order.createdAt)}\n'),
    );
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

    // Center alignment for footer
    bytes.addAll([0x1B, 0x61, 0x01]);
    bytes.addAll(
      utf8.encode(
        'الإجمالي: ${Formatters.formatCurrency(order.totalAmount)}\n',
      ),
    );
    bytes.addAll(utf8.encode('يرجى التحضير فوراً\n\n\n'));

    // Cut paper command: GS V 66 0 (0x1D, 0x56, 0x42, 0x00)
    bytes.addAll([0x1D, 0x56, 0x42, 0x00]);

    return bytes;
  }

  /// Generates printable customer tax invoice receipt text with VAT breakdown.
  String generateCustomerInvoiceText(
    OrderEntity order, {
    String? tableDisplay,
    String restaurantName = 'مطعم الأصالة والنكهة',
    String taxNumber = '300123456700003',
  }) {
    final buffer = StringBuffer();
    const line = '--------------------------------';
    const doubleLine = '================================';

    buffer.writeln(doubleLine);
    buffer.writeln('       $restaurantName       ');
    buffer.writeln('    فاتورة ضريبية مبسطة / Tax Invoice  ');
    buffer.writeln('الرقم الضريبي: $taxNumber');
    buffer.writeln(doubleLine);
    buffer.writeln('رقم الفاتورة: ${Formatters.formatOrderId(order.id)}');
    buffer.writeln('التاريخ: ${Formatters.formatDateTime(order.createdAt)}');
    if (tableDisplay != null) {
      buffer.writeln('طاولة رقم: $tableDisplay');
    }
    if (order.paymentMethod != null) {
      buffer.writeln('طريقة الدفع: ${order.paymentMethod!.labelAr}');
    }
    buffer.writeln(line);
    buffer.writeln('الكمية   الصنف                  السعر');
    buffer.writeln(line);

    for (final item in order.items) {
      buffer.writeln(
        '${item.quantity.toString().padRight(3)} x ${item.menuItem.name.padRight(18)} ${Formatters.formatCurrency(item.itemTotal)}',
      );
      if (item.selectedModifiers.isNotEmpty) {
        final mods = item.selectedModifiers.map((m) => m.name).join(', ');
        buffer.writeln('     + $mods');
      }
    }

    buffer.writeln(line);
    buffer.writeln('المجموع الفرعي: ${Formatters.formatCurrency(order.subtotal)}');
    if (order.discountAmount > 0) {
      buffer.writeln('الخصم: -${Formatters.formatCurrency(order.discountAmount)}');
    }
    buffer.writeln('ضريبة القيمة المضافة (15%): ${Formatters.formatCurrency(order.taxAmount)}');
    buffer.writeln(doubleLine);
    buffer.writeln('الإجمالي النهائي: ${Formatters.formatCurrency(order.totalAmount)}');
    buffer.writeln(doubleLine);
    buffer.writeln('     شكراً لزيارتكم ونتطلع لخدمتكم دائماً    ');
    buffer.writeln(doubleLine);

    return buffer.toString();
  }

  /// Generates standard ESC/POS binary byte stream for customer tax invoice thermal receipt.
  List<int> generateInvoiceEscPosBytes(
    OrderEntity order, {
    String? tableDisplay,
    bool kickCashDrawer = false,
  }) {
    final bytes = <int>[];

    // Cash drawer kick pulse: ESC p 0 25 250 (0x1B, 0x70, 0x00, 0x19, 0xFA)
    if (kickCashDrawer) {
      bytes.addAll([0x1B, 0x70, 0x00, 0x19, 0xFA]);
    }

    // Initialize printer: ESC @ (0x1B, 0x40)
    bytes.addAll([0x1B, 0x40]);

    // Center alignment: ESC a 1 (0x1B, 0x61, 0x01)
    bytes.addAll([0x1B, 0x61, 0x01]);

    // Header (Bold)
    bytes.addAll([0x1B, 0x45, 0x01]);
    bytes.addAll(utf8.encode('مطعم الأصالة والنكهة\n'));
    bytes.addAll(utf8.encode('فاتورة ضريبية مبسطة\n'));
    bytes.addAll(utf8.encode('الرقم الضريبي: 300123456700003\n'));
    bytes.addAll([0x1B, 0x45, 0x00]);

    // Left alignment
    bytes.addAll([0x1B, 0x61, 0x00]);
    bytes.addAll(utf8.encode('--------------------------------\n'));
    bytes.addAll(
      utf8.encode('رقم الفاتورة: ${Formatters.formatOrderId(order.id)}\n'),
    );
    bytes.addAll(
      utf8.encode('التاريخ: ${Formatters.formatDateTime(order.createdAt)}\n'),
    );
    if (tableDisplay != null) {
      bytes.addAll(utf8.encode('طاولة: $tableDisplay\n'));
    }
    if (order.paymentMethod != null) {
      bytes.addAll(utf8.encode('طريقة الدفع: ${order.paymentMethod!.labelAr}\n'));
    }
    bytes.addAll(utf8.encode('--------------------------------\n'));

    // Items
    for (final item in order.items) {
      final line =
          '${item.quantity}x ${item.menuItem.name} ${Formatters.formatCurrency(item.itemTotal)}\n';
      bytes.addAll(utf8.encode(line));
      if (item.selectedModifiers.isNotEmpty) {
        final mods = item.selectedModifiers.map((m) => m.name).join(', ');
        bytes.addAll(utf8.encode('  + $mods\n'));
      }
    }

    bytes.addAll(utf8.encode('--------------------------------\n'));
    bytes.addAll(
      utf8.encode(
        'المجموع الفرعي: ${Formatters.formatCurrency(order.subtotal)}\n',
      ),
    );
    if (order.discountAmount > 0) {
      bytes.addAll(
        utf8.encode(
          'الخصم: -${Formatters.formatCurrency(order.discountAmount)}\n',
        ),
      );
    }
    bytes.addAll(
      utf8.encode(
        'الضريبة 15%: ${Formatters.formatCurrency(order.taxAmount)}\n',
      ),
    );
    bytes.addAll(utf8.encode('================================\n'));

    // Total (Bold & Center)
    bytes.addAll([0x1B, 0x61, 0x01]);
    bytes.addAll([0x1B, 0x45, 0x01]);
    bytes.addAll(
      utf8.encode(
        'الإجمالي النهائي: ${Formatters.formatCurrency(order.totalAmount)}\n',
      ),
    );
    bytes.addAll([0x1B, 0x45, 0x00]);
    bytes.addAll(utf8.encode('شكراً لزيارتكم ونتطلع لخدمتكم دائماً\n\n\n'));

    // Cut paper
    bytes.addAll([0x1D, 0x56, 0x42, 0x00]);

    return bytes;
  }

  /// Dispatches the print job to connected thermal printer across local network or fallback.
  Future<bool> printKitchenTicket(
    OrderEntity order, {
    String? tableDisplay,
    String? printerIp,
  }) async {
    final bytes = generateEscPosBytes(order, tableDisplay: tableDisplay);

    if (printerIp != null && printerIp.trim().isNotEmpty) {
      AppLogger.info('Printing kitchen ticket to network printer at $printerIp');
      return _networkPrinter.sendRawBytes(
        ipAddress: printerIp.trim(),
        bytes: bytes,
      );
    }

    // Hardware simulation fallback when no physical printer IP is configured
    await Future.delayed(const Duration(milliseconds: 300));
    AppLogger.info('Kitchen ticket printed locally (hardware simulation)');
    return true;
  }

  /// Dispatches the customer tax invoice print job.
  Future<bool> printCustomerInvoice(
    OrderEntity order, {
    String? tableDisplay,
    String? printerIp,
    bool kickDrawer = false,
  }) async {
    final bytes = generateInvoiceEscPosBytes(
      order,
      tableDisplay: tableDisplay,
      kickCashDrawer: kickDrawer,
    );

    if (printerIp != null && printerIp.trim().isNotEmpty) {
      AppLogger.info('Printing customer invoice to network printer at $printerIp');
      return _networkPrinter.sendRawBytes(
        ipAddress: printerIp.trim(),
        bytes: bytes,
      );
    }

    // Hardware simulation fallback when no physical printer IP is configured
    await Future.delayed(const Duration(milliseconds: 300));
    AppLogger.info('Customer invoice printed locally (hardware simulation)');
    return true;
  }
}

final ticketPrinterServiceProvider = Provider<TicketPrinterService>((ref) {
  return TicketPrinterService(
    networkPrinterService: ref.watch(networkPrinterServiceProvider),
  );
});

