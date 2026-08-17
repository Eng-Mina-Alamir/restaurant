import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'push_notification_service.dart';

/// Handles navigation and in-app banners when a notification is received or tapped.
class NotificationHandler {
  NotificationHandler(this._notificationService);

  final PushNotificationService _notificationService;

  /// Handles user tapping on a notification action.
  void onNotificationTapped(BuildContext context, AppNotification notification) {
    _notificationService.markAsRead(notification.id);

    final type = notification.data['type']?.toString();
    final orderId = notification.data['orderId']?.toString();

    switch (type) {
      case 'order':
        if (orderId != null) {
          context.push('/customer/orders');
        }
        break;
      case 'delivery':
        context.push('/driver');
        break;
      case 'kds':
        context.push('/kds');
        break;
      case 'table':
        context.push('/waiter');
        break;
      default:
        break;
    }
  }

  /// Displays an in-app snackbar banner for a foreground notification.
  void showInAppBanner(BuildContext context, AppNotification notification) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(notification.body),
          ],
        ),
        action: SnackBarAction(
          label: 'عرض',
          onPressed: () => onNotificationTapped(context, notification),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

final notificationHandlerProvider = Provider<NotificationHandler>((ref) {
  final service = ref.watch(pushNotificationServiceProvider);
  return NotificationHandler(service);
});
