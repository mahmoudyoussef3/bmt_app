import '../repositories/captain_notifications_repository.dart';

class MarkAllCaptainNotificationsReadUseCase {
  const MarkAllCaptainNotificationsReadUseCase(this._repo);
  final CaptainNotificationsRepository _repo;
  Future<void> call() => _repo.markAllAsRead();
}
