import '../../domain/entities/client_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/mock_notifications_datasource.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  const NotificationsRepositoryImpl(this._datasource);

  final MockNotificationsDatasource _datasource;

  @override
  Future<List<ClientNotification>> getNotifications() async {
    final notifications = await _datasource.getNotifications();
    return notifications
        .map((notification) => notification.toEntity())
        .toList();
  }
}
