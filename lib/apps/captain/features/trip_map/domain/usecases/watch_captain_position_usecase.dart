import '../entities/captain_location_fix.dart';
import '../repositories/captain_location_stream_repository.dart';

class WatchCaptainPositionUseCase {
  const WatchCaptainPositionUseCase(this._repository);

  final CaptainLocationStreamRepository _repository;

  Stream<CaptainLocationFix> call() => _repository.watchPosition();
}
