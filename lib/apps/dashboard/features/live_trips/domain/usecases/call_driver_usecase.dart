import '../repositories/live_trips_repository.dart';

class CallDriverUseCase {
  final LiveTripsRepository _repository;

  const CallDriverUseCase(this._repository);

  Future<String> call(String driverPhone) =>
      _repository.callDriver(driverPhone);
}
