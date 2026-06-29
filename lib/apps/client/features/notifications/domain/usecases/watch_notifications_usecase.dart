import '../entities/client_notification.dart';
import '../repositories/notifications_repository.dart';

class WatchNotificationsUseCase {
  const WatchNotificationsUseCase(this._repository);

  final NotificationsRepository _repository;

  Stream<List<ClientNotification>> call() => _repository.watchNotifications();
}
