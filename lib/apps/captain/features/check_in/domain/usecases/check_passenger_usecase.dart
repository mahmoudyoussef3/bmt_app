import '../entities/check_in_result.dart';
import '../repositories/check_in_repository.dart';

class CheckPassengerUseCase {
  const CheckPassengerUseCase(this._repository);

  final CheckInRepository _repository;

  Future<CheckInResult> call({
    required String tripId,
    required String passengerId,
    required CheckInStatus status,
  }) {
    return _repository.checkPassenger(
      tripId: tripId,
      passengerId: passengerId,
      status: status,
    );
  }
}
