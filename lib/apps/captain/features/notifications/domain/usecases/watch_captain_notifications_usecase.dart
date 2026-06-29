import '../entities/captain_notification.dart';
import '../repositories/captain_notifications_repository.dart';

class WatchCaptainNotificationsUseCase {
  const WatchCaptainNotificationsUseCase(this._repo);
  final CaptainNotificationsRepository _repo;
  Stream<List<CaptainNotification>> call() => _repo.watchNotifications();
}
