import '../../domain/entities/captain_notification.dart';
import '../../domain/repositories/captain_notifications_repository.dart';
import '../datasources/supabase_captain_notifications_datasource.dart';

class CaptainNotificationsRepositoryImpl
    implements CaptainNotificationsRepository {
  const CaptainNotificationsRepositoryImpl(this._datasource);

  final CaptainNotificationsDatasource _datasource;

  @override
  Future<List<CaptainNotification>> getNotifications() async =>
      (await _datasource.getNotifications()).map((m) => m.toEntity()).toList();

  @override
  Stream<List<CaptainNotification>> watchNotifications() =>
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
