import '../entities/notification_draft.dart';
import '../repositories/notifications_dispatch_repository.dart';

class SendNotificationUseCase {
  const SendNotificationUseCase(this._repository);

  final NotificationsDispatchRepository _repository;

  /// Sends to a specific user or broadcasts based on [draft.isBroadcast].
  Future<int> call(NotificationDraft draft) async {
    if (draft.isBroadcast) {
      return _repository.broadcast(draft);
    }
    await _repository.sendToUser(
      userId: draft.recipientUserId!,
      draft: draft,
    );
    return 1;
  }
}
