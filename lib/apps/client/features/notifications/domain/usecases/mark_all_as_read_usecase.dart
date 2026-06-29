import '../repositories/notifications_repository.dart';

class MarkAllAsReadUseCase {
  const MarkAllAsReadUseCase(this._repository);

  final NotificationsRepository _repository;

  Future<void> call() => _repository.markAllAsRead();
}
