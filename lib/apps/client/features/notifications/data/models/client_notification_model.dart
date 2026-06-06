import '../../domain/entities/client_notification.dart';

class ClientNotificationModel {
  const ClientNotificationModel({
    required this.title,
    required this.description,
    required this.time,
    required this.iconKey,
    required this.unread,
  });

  final String title;
  final String description;
  final String time;
  final String iconKey;
  final bool unread;

  ClientNotification toEntity() {
    return ClientNotification(
      title: title,
      description: description,
      time: time,
      iconKey: iconKey,
      unread: unread,
    );
  }
}
