import '../repositories/operational_alerts_repository.dart';

class WatchUnreadAlertsCountUseCase {
  const WatchUnreadAlertsCountUseCase(this._repository);

  final OperationalAlertsRepository _repository;

  Stream<int> call() => _repository.watchUnreadCount();
}
