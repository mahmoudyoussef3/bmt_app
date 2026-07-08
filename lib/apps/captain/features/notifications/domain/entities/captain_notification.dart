enum CaptainNotificationCategory {
  trip,
  passenger,
  assignment,
  emergency,
  announcement,
  system,
  general;

  static CaptainNotificationCategory fromString(String s) => values.firstWhere(
    (e) => e.name == s,
    orElse: () => CaptainNotificationCategory.general,
  );
}

enum CaptainNotificationPriority {
  low,
  normal,
  high,
  urgent;

  static CaptainNotificationPriority fromString(String s) => values.firstWhere(
    (e) => e.name == s,
    orElse: () => CaptainNotificationPriority.normal,
  );
}

class CaptainNotification {
  const CaptainNotification({
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

  CaptainNotification copyWith({bool? isRead}) => CaptainNotification(
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
