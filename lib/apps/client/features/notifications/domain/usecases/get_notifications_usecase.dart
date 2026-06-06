import '../entities/client_notification.dart';
import '../repositories/notifications_repository.dart';

class GetNotificationsUseCase {
  const GetNotificationsUseCase(this._repository);

  final NotificationsRepository _repository;

  Future<List<ClientNotification>> call() {
    return _repository.getNotifications();
  }
}
