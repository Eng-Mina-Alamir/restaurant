import '../../../../core/utils/formatters.dart';

enum ShiftStatus {
  open('مفتوحة'),
  closed('مغلقة');

  final String labelAr;
  const ShiftStatus(this.labelAr);
}

/// Represents a cashier / POS cash drawer work shift.
class ShiftEntity {
  const ShiftEntity({
    required this.id,
    required this.cashierId,
    required this.cashierName,
    required this.openedAt,
    this.closedAt,
    required this.openingCashFloat,
    this.cashSales = 0.0,
    this.cardSales = 0.0,
    this.walletSales = 0.0,
    this.totalOrdersCount = 0,
    this.actualCashCount,
    this.status = ShiftStatus.open,
    this.notes,
  });

  final String id;
  final String cashierId;
  final String cashierName;
  final DateTime openedAt;
  final DateTime? closedAt;
  final double openingCashFloat;
  final double cashSales;
  final double cardSales;
  final double walletSales;
  final int totalOrdersCount;
  final double? actualCashCount;
  final ShiftStatus status;
  final String? notes;

  double get totalSales => cashSales + cardSales + walletSales;

  /// Expected cash in drawer at closing: Opening float + all cash sales.
  double get expectedCashInDrawer => openingCashFloat + cashSales;

  /// Cash discrepancy (عجز أو زيادة نقدية): actual - expected.
  double? get cashDiscrepancy {
    if (actualCashCount == null) return null;
    return actualCashCount! - expectedCashInDrawer;
  }

  ShiftEntity copyWith({
    String? id,
    String? cashierId,
    String? cashierName,
    DateTime? openedAt,
    DateTime? closedAt,
    double? openingCashFloat,
    double? cashSales,
    double? cardSales,
    double? walletSales,
    int? totalOrdersCount,
    double? actualCashCount,
    ShiftStatus? status,
    String? notes,
  }) {
    return ShiftEntity(
      id: id ?? this.id,
      cashierId: cashierId ?? this.cashierId,
      cashierName: cashierName ?? this.cashierName,
      openedAt: openedAt ?? this.openedAt,
      closedAt: closedAt ?? this.closedAt,
      openingCashFloat: openingCashFloat ?? this.openingCashFloat,
      cashSales: cashSales ?? this.cashSales,
      cardSales: cardSales ?? this.cardSales,
      walletSales: walletSales ?? this.walletSales,
      totalOrdersCount: totalOrdersCount ?? this.totalOrdersCount,
      actualCashCount: actualCashCount ?? this.actualCashCount,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  /// Formatted Z-Report text summary for end-of-day printing.
  String generateZReportText() {
    final buffer = StringBuffer();
    const line = '--------------------------------';
    const doubleLine = '================================';

    buffer.writeln(doubleLine);
    buffer.writeln('    تقرير إقفال الوردية (Z-Report)   ');
    buffer.writeln('          مطعم الأصالة والنكهة          ');
    buffer.writeln(doubleLine);
    buffer.writeln('رقم الوردية: $id');
    buffer.writeln('الكاشير: $cashierName');
    buffer.writeln('وقت البدء: ${Formatters.formatDateTime(openedAt)}');
    if (closedAt != null) {
      buffer.writeln('وقت الإقفال: ${Formatters.formatDateTime(closedAt!)}');
    }
    buffer.writeln('حالة الوردية: ${status.labelAr}');
    buffer.writeln(line);
    buffer.writeln('المبلغ الافتتاحي (Float): ${Formatters.formatCurrency(openingCashFloat)}');
    buffer.writeln('إجمالي عدد الطلبات: $totalOrdersCount طلب');
    buffer.writeln(line);
    buffer.writeln('مبيعات النقد (Cash): ${Formatters.formatCurrency(cashSales)}');
    buffer.writeln('مبيعات الشبكة (Card): ${Formatters.formatCurrency(cardSales)}');
    buffer.writeln('مبيعات المحفظة (Wallet): ${Formatters.formatCurrency(walletSales)}');
    buffer.writeln(doubleLine);
    buffer.writeln('إجمالي المبيعات: ${Formatters.formatCurrency(totalSales)}');
    buffer.writeln('النقد المتوقع بالدرج: ${Formatters.formatCurrency(expectedCashInDrawer)}');
    if (actualCashCount != null) {
      buffer.writeln('النقد الفعلي المسلم: ${Formatters.formatCurrency(actualCashCount!)}');
      final diff = cashDiscrepancy ?? 0.0;
      final diffLabel = diff == 0 ? 'مطابق تماماً (0 ر.س)' : (diff > 0 ? '+${Formatters.formatCurrency(diff)} (زيادة)' : '${Formatters.formatCurrency(diff)} (عجز)');
      buffer.writeln('الفارق النقدي: $diffLabel');
    }
    buffer.writeln(doubleLine);
    buffer.writeln('       توقيع المسؤول: ____________      ');
    buffer.writeln(doubleLine);

    return buffer.toString();
  }
}
