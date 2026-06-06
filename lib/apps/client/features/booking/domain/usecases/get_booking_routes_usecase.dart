import '../entities/booking_option.dart';
import '../entities/booking_search_query.dart';
import '../repositories/booking_repository.dart';

class GetBookingRoutesUseCase {
  const GetBookingRoutesUseCase(this._repository);

  final BookingRepository _repository;

  Future<List<RouteOptionData>> call(BookingSearchQuery query) {
    return _repository.getRoutes(query);
  }
}
