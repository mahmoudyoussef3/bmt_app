import '../../domain/entities/notification_draft.dart';
import '../../domain/repositories/notifications_dispatch_repository.dart';
import '../datasources/supabase_notifications_dispatch_datasource.dart';

class NotificationsDispatchRepositoryImpl
    implements NotificationsDispatchRepository {
  const NotificationsDispatchRepositoryImpl(this._datasource);

  final NotificationsDispatchDatasource _datasource;

  @override
  Future<void> sendToUser({
    required String userId,
    required NotificationDraft draft,
  }) => _datasource.insertForUser(userId: userId, draft: draft);

  @override
  Future<int> broadcast(NotificationDraft draft) =>
      _datasource.broadcastRpc(draft);
}
