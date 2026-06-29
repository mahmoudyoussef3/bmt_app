import '../entities/booking_option.dart';
import '../entities/booking_search_query.dart';
import '../repositories/booking_repository.dart';

class GetBookingRoutesUseCase {
  const GetBookingRoutesUseCase(this._repository);

  final BookingRepository _repository;

  Future<List<RouteOptionData>> call(BookingSearchQuery query) async {
    final routes = await _repository.getRoutes(query);
    return routes.where(_isBookable).toList();
  }

  bool _isBookable(RouteOptionData route) {
    return route.availableTrips.any(
      (trip) =>
          trip.id.trim().isNotEmpty &&
          trip.availableSeats > 0 &&
          !_isPendingPrice(trip.price),
    );
  }

  bool _isPendingPrice(String value) {
    return value.trim().toLowerCase() == 'price pending';
  }
}
