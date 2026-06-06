import '../entities/daily_booking_data.dart';
import '../repositories/booking_repository.dart';

class GetDailyBookingDataUseCase {
  const GetDailyBookingDataUseCase(this._repository);

  final BookingRepository _repository;

  Future<DailyBookingData> call() {
    return _repository.getDailyBookingData();
  }
}
