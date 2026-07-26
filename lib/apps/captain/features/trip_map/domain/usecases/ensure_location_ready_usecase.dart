import '../entities/location_gate.dart';
import '../repositories/captain_location_stream_repository.dart';

class EnsureLocationReadyUseCase {
  const EnsureLocationReadyUseCase(this._repository);

  final CaptainLocationStreamRepository _repository;

  Future<LocationGate> call() => _repository.ensureReady();
}
