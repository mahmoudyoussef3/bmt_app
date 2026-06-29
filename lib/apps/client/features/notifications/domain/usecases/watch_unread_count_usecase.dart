import '../repositories/notifications_repository.dart';

class WatchUnreadCountUseCase {
  const WatchUnreadCountUseCase(this._repository);

  final NotificationsRepository _repository;

  Stream<int> call() => _repository.watchUnreadCount();
}
