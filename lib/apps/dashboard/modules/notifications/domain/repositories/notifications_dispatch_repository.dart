import '../entities/notification_draft.dart';

abstract class NotificationsDispatchRepository {
  /// Send a notification to a single user (by [userId]).
  Future<void> sendToUser({
    required String userId,
    required NotificationDraft draft,
  });

  /// Broadcast via the `broadcast_notification` RPC to all matching users.
  Future<int> broadcast(NotificationDraft draft);
}
