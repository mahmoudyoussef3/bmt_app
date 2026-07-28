import '../../domain/entities/client_notification.dart';

class ClientNotificationModel {
  const ClientNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.isRead,
    required this.createdAt,
    this.type = '',
    this.actionUrl,
    this.data = const {},
    this.priority = NotificationPriority.normal,
  });

  final String id;
  final String title;
  final String body;
  final NotificationCategory category;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final String? actionUrl;
  final Map<String, dynamic> data;
  final NotificationPriority priority;

  factory ClientNotificationModel.fromMap(Map<String, dynamic> map) {
    return ClientNotificationModel(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      category: NotificationCategory.fromString(
        map['category'] as String? ?? map['type'] as String? ?? 'general',
      ),
      type: map['type'] as String? ?? '',
      isRead: map['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      actionUrl: map['action_url'] as String?,
      data: (map['data'] as Map<String, dynamic>?) ?? const {},
      priority: NotificationPriority.fromString(
        map['priority'] as String? ?? 'normal',
      ),
    );
  }

  ClientNotification toEntity() => ClientNotification(
        id: id,
        title: title,
        body: body,
        category: category,
        type: type,
        isRead: isRead,
        createdAt: createdAt,
        actionUrl: actionUrl,
        data: data,
        priority: priority,
      );
}
