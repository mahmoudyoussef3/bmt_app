import '../entities/seat_option.dart';
import '../repositories/seat_selection_repository.dart';

class GetSeatSelectionDataUseCase {
  const GetSeatSelectionDataUseCase(this._repository);

  final SeatSelectionRepository _repository;

  Future<SeatSelectionData> call() {
    return _repository.getSeatSelectionData();
  }
}
