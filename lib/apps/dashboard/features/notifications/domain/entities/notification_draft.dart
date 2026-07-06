enum NotificationTargetApp { client, captain, all }

enum DashboardNotificationCategory {
  booking,
  payment,
  trip,
  announcement,
  promotion,
  emergency,
  subscription,
  system,
  general;

  String get label => switch (this) {
    DashboardNotificationCategory.booking => 'Booking',
    DashboardNotificationCategory.payment => 'Payment',
    DashboardNotificationCategory.trip => 'Trip',
    DashboardNotificationCategory.announcement => 'Announcement',
    DashboardNotificationCategory.promotion => 'Promotion',
    DashboardNotificationCategory.emergency => 'Emergency',
    DashboardNotificationCategory.subscription => 'Subscription',
    DashboardNotificationCategory.system => 'System',
    DashboardNotificationCategory.general => 'General',
  };
}

class NotificationDraft {
  const NotificationDraft({
    required this.title,
    required this.body,
    required this.category,
    required this.targetApp,
    this.recipientUserId,
    this.actionUrl,
    this.data = const {},
  });

  /// If null → broadcast to all users of [targetApp].
  final String? recipientUserId;
  final String title;
  final String body;
  final DashboardNotificationCategory category;
  final NotificationTargetApp targetApp;
  final String? actionUrl;
  final Map<String, dynamic> data;

  bool get isBroadcast => recipientUserId == null;
}
