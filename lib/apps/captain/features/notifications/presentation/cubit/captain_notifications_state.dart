import '../../domain/entities/captain_notification.dart';

sealed class CaptainNotificationsState {
  const CaptainNotificationsState();
}

class CaptainNotificationsInitial extends CaptainNotificationsState {
  const CaptainNotificationsInitial();
}

class CaptainNotificationsLoading extends CaptainNotificationsState {
  const CaptainNotificationsLoading();
}

class CaptainNotificationsLoaded extends CaptainNotificationsState {
  const CaptainNotificationsLoaded(this.notifications);

  final List<CaptainNotification> notifications;

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  CaptainNotificationsLoaded withReadToggled(String id) {
    final updated = notifications
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();
    return CaptainNotificationsLoaded(updated);
  }

  CaptainNotificationsLoaded withAllRead() {
    final updated = notifications.map((n) => n.copyWith(isRead: true)).toList();
    return CaptainNotificationsLoaded(updated);
  }
}

class CaptainNotificationsError extends CaptainNotificationsState {
  const CaptainNotificationsError(this.message);
  final String message;
}
