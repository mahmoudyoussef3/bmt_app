import '../entities/client_notification.dart';

abstract class NotificationsRepository {
  Future<List<ClientNotification>> getNotifications();
  Stream<List<ClientNotification>> watchNotifications();
  Stream<int> watchUnreadCount();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
}
