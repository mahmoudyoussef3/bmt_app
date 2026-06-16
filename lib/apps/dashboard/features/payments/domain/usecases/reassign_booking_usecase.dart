import '../repositories/payments_repository.dart';

class GetAvailableTripsUseCase {
  const GetAvailableTripsUseCase(this._repository);
  final PaymentsRepository _repository;
  Future<List<Map<String, dynamic>>> call() => _repository.getAvailableTrips();
}

class ReassignBookingUseCase {
  const ReassignBookingUseCase(this._repository);
  final PaymentsRepository _repository;
  Future<void> call(String bookingId, String newTripId) =>
      _repository.reassignBooking(bookingId, newTripId);
}
