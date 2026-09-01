import '../../../../core/domain/enums.dart';
import '../entities/restaurant_table.dart';

/// Domain service for validating and processing floor operations like table transfers and merges.
abstract final class TableOperationService {
  TableOperationService._();

  /// Validates whether an active order can be transferred from [sourceTable] to [targetTable].
  static (bool isValid, String? errorReason) validateTransfer({
    required RestaurantTable sourceTable,
    required RestaurantTable targetTable,
    required int currentGuestCount,
  }) {
    if (sourceTable.id == targetTable.id) {
      return (false, 'لا يمكن نقل الطلب إلى نفس الطاولة');
    }

    if (sourceTable.status != TableStatus.occupied) {
      return (false, 'طاولة المصدر ليست مشغولة حالياً');
    }

    if (targetTable.status == TableStatus.occupied) {
      return (false, 'الطاولة المطلوبة رقم (${targetTable.tableNumber}) مشغولة بطلب آخر');
    }

    if (targetTable.status == TableStatus.needsCleaning) {
      return (false, 'الطاولة رقم (${targetTable.tableNumber}) تحتاج إلى تنظيف أولاً');
    }

    if (targetTable.capacity < currentGuestCount) {
      return (
        false,
        'سعة الطاولة الجديدة (${targetTable.capacity} أفراد) أصغر من عدد الضيوف ($currentGuestCount أفراد)'
      );
    }

    return (true, null);
  }

  /// Calculates urgency and idle minutes for an occupied table.
  /// Returns a severity level: 0 = Normal, 1 = Warning (15+ mins), 2 = Critical (30+ mins).
  static (int severityLevel, String statusDescription) calculateTableUrgency({
    required RestaurantTable table,
    required DateTime? orderCreatedAt,
    required bool hasServiceRequest,
    required bool isBillRequested,
  }) {
    if (hasServiceRequest) {
      return (2, 'طلب خدمة عاجل بانتظار الويتر 🔔');
    }

    if (isBillRequested) {
      return (2, 'الضيوف بانتظار الفاتورة 🧾');
    }

    if (table.status == TableStatus.needsCleaning) {
      return (1, 'الطاولة بحاجة للتنظيف والتعقيم 🧹');
    }

    if (table.status == TableStatus.occupied && orderCreatedAt != null) {
      final elapsedMinutes = DateTime.now().difference(orderCreatedAt).inMinutes;
      if (elapsedMinutes >= 45) {
        return (1, 'جلوس طويل ($elapsedMinutes دقيقة)');
      }
    }

    return (0, 'طبيعي');
  }
}
