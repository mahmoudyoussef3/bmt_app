import '../repositories/captain_notifications_repository.dart';

class WatchCaptainUnreadCountUseCase {
  const WatchCaptainUnreadCountUseCase(this._repo);
  final CaptainNotificationsRepository _repo;
  Stream<int> call() => _repo.watchUnreadCount();
}
