import '../repositories/operational_alerts_repository.dart';

class MarkAlertReadUseCase {
  const MarkAlertReadUseCase(this._repository);

  final OperationalAlertsRepository _repository;

  Future<void> call(String id) => _repository.markAsRead(id);
}
