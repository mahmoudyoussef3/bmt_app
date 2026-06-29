import '../../domain/entities/client_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/supabase_notifications_datasource.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  const NotificationsRepositoryImpl(this._datasource);

  final NotificationsDatasource _datasource;

  @override
  Future<List<ClientNotification>> getNotifications() async =>
      (await _datasource.getNotifications()).map((m) => m.toEntity()).toList();

  @override
  Stream<List<ClientNotification>> watchNotifications() =>
      _datasource.watchNotifications().map(
            (rows) => rows.map((m) => m.toEntity()).toList(),
          );

  @override
  Stream<int> watchUnreadCount() => _datasource.watchUnreadCount();

  @override
  Future<void> markAsRead(String id) => _datasource.markAsRead(id);

  @override
  Future<void> markAllAsRead() => _datasource.markAllAsRead();
}
