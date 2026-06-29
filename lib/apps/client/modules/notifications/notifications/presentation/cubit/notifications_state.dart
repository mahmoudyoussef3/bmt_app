import '../../domain/entities/client_notification.dart';

sealed class NotificationsState {
  const NotificationsState();
}

class NotificationsInitial extends NotificationsState {
  const NotificationsInitial();
}

class NotificationsLoading extends NotificationsState {
  const NotificationsLoading();
}

class NotificationsLoaded extends NotificationsState {
  const NotificationsLoaded(this.notifications, {this.activeCategory});

  final List<ClientNotification> notifications;
  final NotificationCategory? activeCategory;

  List<ClientNotification> get filtered => activeCategory == null
      ? notifications
      : notifications
          .where((n) => n.category == activeCategory)
          .toList();

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationsLoaded withCategory(NotificationCategory? cat) =>
      NotificationsLoaded(notifications, activeCategory: cat);

  NotificationsLoaded withReadToggled(String id) {
    final updated = notifications.map((n) {
      return n.id == id ? n.copyWith(isRead: true) : n;
    }).toList();
    return NotificationsLoaded(updated, activeCategory: activeCategory);
  }

  NotificationsLoaded withAllRead() {
    final updated = notifications.map((n) => n.copyWith(isRead: true)).toList();
    return NotificationsLoaded(updated, activeCategory: activeCategory);
  }
}

class NotificationsError extends NotificationsState {
  const NotificationsError(this.message);

  final String message;
}
