import '../../domain/entities/client_notification.dart';

sealed class NotificationsState {
  const NotificationsState();
}

class NotificationsLoading extends NotificationsState {
  const NotificationsLoading();
}

class NotificationsLoaded extends NotificationsState {
  const NotificationsLoaded(this.notifications);

  final List<ClientNotification> notifications;
}

class NotificationsError extends NotificationsState {
  const NotificationsError(this.message);

  final String message;
}
