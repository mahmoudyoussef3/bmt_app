import '../repositories/captain_notifications_repository.dart';

class MarkCaptainNotificationReadUseCase {
  const MarkCaptainNotificationReadUseCase(this._repo);
  final CaptainNotificationsRepository _repo;
  Future<void> call(String id) => _repo.markAsRead(id);
}
