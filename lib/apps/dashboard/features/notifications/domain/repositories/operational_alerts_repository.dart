import '../entities/operational_alert.dart';

abstract class OperationalAlertsRepository {
  Stream<List<OperationalAlert>> watchAlerts();
  Stream<int> watchUnreadCount();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
}
