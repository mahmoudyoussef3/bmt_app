import '../entities/booking_option.dart';
import '../entities/booking_search_query.dart';
import '../repositories/booking_repository.dart';

class GetAvailableTripsUseCase {
  const GetAvailableTripsUseCase(this._repository);

  final BookingRepository _repository;

  Future<List<AvailableTripData>> call(BookingSearchQuery query) {
    return _repository.getAvailableTrips(query);
  }
}
