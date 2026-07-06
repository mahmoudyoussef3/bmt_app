import '../../domain/entities/operational_alert.dart';

class OperationalAlertModel {
  const OperationalAlertModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    required this.priority,
    this.actionUrl,
    this.data = const {},
  });

  final String id;
  final OperationalAlertType type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final OperationalAlertPriority priority;
  final String? actionUrl;
  final Map<String, dynamic> data;

  factory OperationalAlertModel.fromMap(Map<String, dynamic> map) {
    return OperationalAlertModel(
      id: map['id'] as String,
      type: OperationalAlertType.fromString(
        map['type'] as String? ?? 'general',
      ),
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      isRead: map['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      priority: OperationalAlertPriority.fromString(
        map['priority'] as String? ?? 'normal',
      ),
      actionUrl: map['action_url'] as String?,
      data: (map['data'] as Map<String, dynamic>?) ?? const {},
    );
  }

  OperationalAlert toEntity() => OperationalAlert(
    id: id,
    type: type,
    title: title,
    body: body,
    isRead: isRead,
    createdAt: createdAt,
    priority: priority,
    actionUrl: actionUrl,
    data: data,
  );
}
