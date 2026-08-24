import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/logger.dart';

/// Categories of push notifications in the restaurant app.
enum NotificationCategory {
  orderStatus,
  newOrder,
  tableAlert,
  deliveryJob,
  system,
}

/// A structured in-app / push notification entity.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    this.data = const {},
    required this.timestamp,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String body;
  final NotificationCategory category;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final bool isRead;

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    NotificationCategory? category,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}

/// Service managing push notification reception, permission requests,
/// and in-app notifications stream.
class PushNotificationService {
  PushNotificationService() {
    _init();
  }

  final StreamController<AppNotification> _controller =
      StreamController<AppNotification>.broadcast();
  final List<AppNotification> _history = [];
  bool _permissionGranted = true;

  Stream<AppNotification> get onNotification => _controller.stream;
  List<AppNotification> get history => List.unmodifiable(_history);
  bool get isPermissionGranted => _permissionGranted;

  void _init() {
    AppLogger.info('PushNotificationService initialized');
  }

  /// Requests notification permissions.
  Future<bool> requestPermission() async {
    _permissionGranted = true;
    AppLogger.info('Push notification permissions granted');
    return true;
  }

  /// Emits a local or received notification into the active stream.
  void showNotification({
    required String title,
    required String body,
    NotificationCategory category = NotificationCategory.system,
    Map<String, dynamic> data = const {},
  }) {
    final notification = AppNotification(
      id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      category: category,
      data: data,
      timestamp: DateTime.now(),
    );

    _history.insert(0, notification);
    _controller.add(notification);
    AppLogger.info('Notification dispatched: ${notification.title}');
  }

  /// Dispatches an order status change notification.
  void notifyOrderStatus({
    required String orderId,
    required String statusAr,
    String? customerId,
  }) {
    showNotification(
      title: 'تحديث الطلب #$orderId',
      body: 'حالة طلبك الآن: $statusAr',
      category: NotificationCategory.orderStatus,
      data: {'orderId': orderId, 'type': 'order'},
    );
  }

  /// Dispatches a new delivery job notification to the driver.
  void notifyDeliveryJob({
    required String deliveryId,
    required String destination,
  }) {
    showNotification(
      title: 'طلب توصيل جديد 🛵',
      body: 'وجهة التوصيل: $destination',
      category: NotificationCategory.deliveryJob,
      data: {'deliveryId': deliveryId, 'type': 'delivery'},
    );
  }

  /// Dispatches a new table order alert for Waiters.
  void notifyNewTableOrder({
    required int tableNumber,
    required String orderId,
  }) {
    showNotification(
      title: 'طلب جديد - طاولة $tableNumber 🍽️',
      body: 'تم استلام طلب جديد #$orderId للطاولة رقم $tableNumber',
      category: NotificationCategory.newOrder,
      data: {'tableNumber': tableNumber, 'orderId': orderId, 'role': 'waiter'},
    );
  }

  /// Dispatches an order cancellation alert for Kitchen staff.
  void notifyKitchenCancelledOrder({required String orderId, String? reason}) {
    showNotification(
      title: '⚠️ تنبيه: إلغاء طلب #$orderId',
      body: reason != null
          ? 'سبب الإلغاء: $reason'
          : 'يرجى إيقاف تحضير هذا الطلب فوراً',
      category: NotificationCategory.orderStatus,
      data: {'orderId': orderId, 'role': 'kitchen'},
    );
  }

  /// Dispatches loyalty points earned notification for customer.
  void notifyLoyaltyPointsEarned({
    required int pointsEarned,
    required int totalPoints,
  }) {
    showNotification(
      title: '🎉 كسبت $pointsEarned نقطة ولاء جديدة!',
      body:
          'رصيد نقاطك الحالي أصبح $totalPoints نقطة. يمكنك استبدالها بمكافآت قيّمة.',
      category: NotificationCategory.system,
      data: {'points': pointsEarned, 'total': totalPoints},
    );
  }

  /// Marks a notification as read in the history list.
  void markAsRead(String id) {
    final idx = _history.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _history[idx] = _history[idx].copyWith(isRead: true);
    }
  }

  /// Clears all stored notifications.
  void clearAll() {
    _history.clear();
  }

  void dispose() {
    _controller.close();
  }
}

/// Provider for [PushNotificationService].
final pushNotificationServiceProvider = Provider<PushNotificationService>((
  ref,
) {
  final service = PushNotificationService();
  ref.onDispose(service.dispose);
  return service;
});
