import '../repositories/operational_alerts_repository.dart';

class MarkAllAlertsReadUseCase {
  const MarkAllAlertsReadUseCase(this._repository);

  final OperationalAlertsRepository _repository;

  Future<void> call() => _repository.markAllAsRead();
}
