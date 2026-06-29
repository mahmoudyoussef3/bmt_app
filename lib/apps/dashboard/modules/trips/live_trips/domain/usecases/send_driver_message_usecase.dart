import '../repositories/live_trips_repository.dart';

class SendDriverMessageUseCase {
  final LiveTripsRepository _repository;

  const SendDriverMessageUseCase(this._repository);

  Future<String> call(String driverPhone, String message) =>
      _repository.sendDriverMessage(driverPhone, message);
}
