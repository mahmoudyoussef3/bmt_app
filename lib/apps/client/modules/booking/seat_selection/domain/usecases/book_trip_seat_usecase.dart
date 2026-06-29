import '../repositories/seat_selection_repository.dart';

class BookTripSeatUseCase {
  final SeatSelectionRepository _repository;

  const BookTripSeatUseCase(this._repository);

  Future<String> call(Map<String, dynamic> params) {
    return _repository.bookTripSeat(params);
  }
}
