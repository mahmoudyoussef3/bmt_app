import '../entities/passenger.dart';
import '../repositories/passenger_manifest_repository.dart';

class UpdatePassengerStatusUseCase {
  const UpdatePassengerStatusUseCase(this._repository);

  final PassengerManifestRepository _repository;

  Future<void> call({
    required String tripPassengerId,
    required PassengerBoardingStatus status,
  }) => _repository.updatePassengerStatus(
    tripPassengerId: tripPassengerId,
    status: status,
  );
}
