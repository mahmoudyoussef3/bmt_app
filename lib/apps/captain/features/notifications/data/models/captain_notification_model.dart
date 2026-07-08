import '../../domain/entities/captain_notification.dart';

class CaptainNotificationModel {
  const CaptainNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.isRead,
    required this.createdAt,
    this.actionUrl,
    this.data = const {},
    this.priority = CaptainNotificationPriority.normal,
  });

  final String id;
  final String title;
  final String body;
  final CaptainNotificationCategory category;
  final bool isRead;
  final DateTime createdAt;
  final String? actionUrl;
  final Map<String, dynamic> data;
  final CaptainNotificationPriority priority;

  factory CaptainNotificationModel.fromMap(Map<String, dynamic> map) =>
      CaptainNotificationModel(
        id: map['id'] as String,
        title: map['title'] as String? ?? '',
        body: map['body'] as String? ?? '',
        category: CaptainNotificationCategory.fromString(
          map['category'] as String? ?? 'general',
        ),
        isRead: map['is_read'] as bool? ?? false,
        createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
        actionUrl: map['action_url'] as String?,
        data: (map['data'] as Map<String, dynamic>?) ?? const {},
        priority: CaptainNotificationPriority.fromString(
          map['priority'] as String? ?? 'normal',
        ),
      );

  CaptainNotification toEntity() => CaptainNotification(
    id: id,
    title: title,
    body: body,
    category: category,
    isRead: isRead,
    createdAt: createdAt,
    actionUrl: actionUrl,
    data: data,
    priority: priority,
  );
}
