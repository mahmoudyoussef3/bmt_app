import '../repositories/notifications_repository.dart';

class MarkAsReadUseCase {
  const MarkAsReadUseCase(this._repository);

  final NotificationsRepository _repository;

  Future<void> call(String id) => _repository.markAsRead(id);
}
