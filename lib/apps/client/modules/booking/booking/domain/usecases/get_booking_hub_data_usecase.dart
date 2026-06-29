import '../entities/booking_hub_data.dart';
import '../repositories/booking_repository.dart';

class GetBookingHubDataUseCase {
  const GetBookingHubDataUseCase(this._repository);

  final BookingRepository _repository;

  Future<BookingHubData> call() {
    return _repository.getBookingHubData();
  }
}
