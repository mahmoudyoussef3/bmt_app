enum NotificationCategory {
  booking,
  payment,
  trip,
  announcement,
  promotion,
  emergency,
  chat,
  subscription,
  system,
  general;

  static NotificationCategory fromString(String s) => values.firstWhere(
        (e) => e.name == s,
        orElse: () => NotificationCategory.general,
      );
}

enum NotificationPriority {
  low,
  normal,
  high,
  urgent;

  static NotificationPriority fromString(String s) => values.firstWhere(
        (e) => e.name == s,
        orElse: () => NotificationPriority.normal,
      );
}

class ClientNotification {
  const ClientNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.isRead,
    required this.createdAt,
    this.actionUrl,
    this.data = const {},
    this.priority = NotificationPriority.normal,
  });

  final String id;
  final String title;
  final String body;
  final NotificationCategory category;
  final bool isRead;
  final DateTime createdAt;
  final String? actionUrl;
  final Map<String, dynamic> data;
  final NotificationPriority priority;

  ClientNotification copyWith({bool? isRead}) => ClientNotification(
        id: id,
        title: title,
        body: body,
        category: category,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
        actionUrl: actionUrl,
        data: data,
        priority: priority,
      );
}
