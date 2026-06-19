import '../../domain/entities/client_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/supabase_notifications_datasource.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  const NotificationsRepositoryImpl(this._datasource);

  final SupabaseNotificationsDatasource _datasource;

  @override
  Future<List<ClientNotification>> getNotifications() async {
    final rows = await _datasource.getNotifications();
    return rows.map((m) => m.toEntity()).toList();
  }
}
