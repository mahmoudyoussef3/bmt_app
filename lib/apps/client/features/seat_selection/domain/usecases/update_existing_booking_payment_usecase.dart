import '../repositories/seat_selection_repository.dart';

class UpdateExistingBookingPaymentUseCase {
  const UpdateExistingBookingPaymentUseCase(this._repository);

  final SeatSelectionRepository _repository;

  Future<Map<String, dynamic>> call(Map<String, dynamic> params) {
    return _repository.updateExistingBookingPayment(params);
  }
}
