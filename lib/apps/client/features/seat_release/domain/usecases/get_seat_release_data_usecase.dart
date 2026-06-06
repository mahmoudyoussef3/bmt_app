import '../entities/seat_release_data.dart';
import '../repositories/seat_release_repository.dart';

class GetSeatReleaseDataUseCase {
  const GetSeatReleaseDataUseCase(this._repository);

  final SeatReleaseRepository _repository;

  Future<SeatReleaseData> call() {
    return _repository.getSeatReleaseData();
  }
}
