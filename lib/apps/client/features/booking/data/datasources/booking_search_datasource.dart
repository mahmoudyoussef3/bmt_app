import '../../domain/entities/booking_search_query.dart';
import '../../domain/entities/search_options.dart';
import '../models/booking_option_model.dart';

abstract class BookingSearchDatasource {
  Future<List<RouteOptionModel>> getRoutes(BookingSearchQuery query);
  Future<List<PopularRouteListModel>> getPopularRoutes();
  Future<List<MapPinOptionModel>> getPickupMapPins();
  Future<List<MapPinOptionModel>> getDestinationMapPins();
  Future<TripSearchOptions> getSearchOptions();
}
