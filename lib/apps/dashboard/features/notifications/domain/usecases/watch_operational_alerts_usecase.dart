import '../entities/operational_alert.dart';
import '../repositories/operational_alerts_repository.dart';

class WatchOperationalAlertsUseCase {
  const WatchOperationalAlertsUseCase(this._repository);

  final OperationalAlertsRepository _repository;

  Stream<List<OperationalAlert>> call() => _repository.watchAlerts();
}
