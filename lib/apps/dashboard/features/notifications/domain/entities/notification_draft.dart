enum NotificationTargetApp {
  client,
  captain,
  all;

  String get label => switch (this) {
    NotificationTargetApp.client => 'تطبيق العملاء',
    NotificationTargetApp.captain => 'تطبيق الكباتن',
    NotificationTargetApp.all => 'كل التطبيقات',
  };
}

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
    DashboardNotificationCategory.booking => 'حجز',
    DashboardNotificationCategory.payment => 'دفع',
    DashboardNotificationCategory.trip => 'رحلة',
    DashboardNotificationCategory.announcement => 'إعلان',
    DashboardNotificationCategory.promotion => 'عرض ترويجي',
    DashboardNotificationCategory.emergency => 'طوارئ',
    DashboardNotificationCategory.subscription => 'اشتراك',
    DashboardNotificationCategory.system => 'النظام',
    DashboardNotificationCategory.general => 'عام',
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
