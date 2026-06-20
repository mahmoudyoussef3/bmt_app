import '../entities/booking_hub_data.dart';
import '../entities/booking_option.dart';
import '../entities/booking_search_query.dart';
import '../entities/daily_booking_data.dart';
import '../entities/search_options.dart';
import '../entities/vehicle_detail.dart';

abstract class BookingRepository {
  Future<BookingHubData> getBookingHubData();

  Future<DailyBookingData> getDailyBookingData();

  Future<List<RouteOptionData>> getRoutes(BookingSearchQuery query);

  Future<List<PopularRouteListData>> getPopularRoutes();

  Future<List<AvailableTripData>> getAvailableTrips(BookingSearchQuery query);

  Future<List<MapPinOption>> getPickupMapPins();

  Future<List<MapPinOption>> getDestinationMapPins();

  Future<TripSearchOptions> getSearchOptions();

  Future<List<VehicleDetailData>> getVehicles({String? routeId});

  Future<VehicleDetailData?> getVehicleById(String id);
}
