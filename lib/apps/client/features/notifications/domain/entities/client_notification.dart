class ClientNotification {
  const ClientNotification({
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
}
