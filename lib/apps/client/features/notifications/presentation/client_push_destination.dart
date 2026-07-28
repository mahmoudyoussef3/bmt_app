import 'package:bmt_app/core/notifications/fcm_service.dart';

import '../domain/entities/client_notification.dart';
import '../domain/entities/notification_destination.dart';

/// Adapts a raw FCM payload to the same routing rules the in-app inbox uses.
///
/// A push and its `notifications` row are written from the same event, so they
/// carry the same `type` and the same ids. Resolving both through
/// [resolveNotificationDestination] is what keeps a tapped push and a tapped
/// inbox entry landing on the same screen.
///
/// FCM data values are always strings, so `data` is passed through as-is; the
/// resolver only ever reads ids out of it as text.
PushDestination? clientPushDestination(Map<String, dynamic> data) {
  final destination = resolveNotificationDestination(
    ClientNotification(
      id: data['id']?.toString() ?? '',
      title: '',
      body: '',
      category: NotificationCategory.fromString(
        data['category']?.toString() ?? 'general',
      ),
      type: data['type']?.toString() ?? data['category']?.toString() ?? '',
      isRead: false,
      createdAt: DateTime.now(),
      actionUrl: data['action_url']?.toString(),
      data: data,
    ),
  );

  if (destination == null) return null;
  return (route: destination.route, arguments: destination.arguments);
}
