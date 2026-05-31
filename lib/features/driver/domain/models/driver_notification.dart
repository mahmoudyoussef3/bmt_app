class DriverNotification {
  final String id;
  final String title;
  final String body;
  bool unread;
  final DateTime time;

  DriverNotification({
    required this.id,
    required this.title,
    required this.body,
    this.unread = true,
    DateTime? time,
  }) : time = time ?? DateTime.now();
}
