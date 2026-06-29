import '../entities/captain_notification.dart';

abstract class CaptainNotificationsRepository {
  Future<List<CaptainNotification>> getNotifications();
  Stream<List<CaptainNotification>> watchNotifications();
  Stream<int> watchUnreadCount();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
}
