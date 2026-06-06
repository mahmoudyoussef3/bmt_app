import '../entities/client_notification.dart';

abstract class NotificationsRepository {
  Future<List<ClientNotification>> getNotifications();
}
