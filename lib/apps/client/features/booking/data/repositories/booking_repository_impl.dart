import '../../domain/entities/booking_hub_data.dart';
import '../../domain/entities/booking_option.dart';
import '../../domain/entities/booking_search_query.dart';
import '../../domain/entities/daily_booking_data.dart';
import '../../domain/entities/vehicle_detail.dart';
import '../../domain/repositories/booking_repository.dart';
import '../datasources/booking_search_datasource.dart';
import '../datasources/daily_booking_datasource.dart';
import '../datasources/vehicle_booking_datasource.dart';

class BookingRepositoryImpl implements BookingRepository {
  const BookingRepositoryImpl({
    required BookingSearchDatasource searchDatasource,
    required DailyBookingDatasource dailyBookingDatasource,
    required VehicleBookingDatasource vehicleDatasource,
  }) : _searchDatasource = searchDatasource,
       _dailyBookingDatasource = dailyBookingDatasource,
       _vehicleDatasource = vehicleDatasource;

  final BookingSearchDatasource _searchDatasource;
  final DailyBookingDatasource _dailyBookingDatasource;
  final VehicleBookingDatasource _vehicleDatasource;

  @override
  Future<BookingHubData> getBookingHubData() {
    return _dailyBookingDatasource.getBookingHubData();
  }

  @override
  Future<DailyBookingData> getDailyBookingData() {
    return _dailyBookingDatasource.getDailyBookingData();
  }

  @override
  Future<List<RouteOptionData>> getRoutes(BookingSearchQuery query) async {
    final models = await _searchDatasource.getRoutes(query);
    return models.map((route) => route.toEntity()).toList();
  }

  @override
  Future<List<PopularRouteListData>> getPopularRoutes() async {
    final models = await _searchDatasource.getPopularRoutes();
    return models.map((route) => route.toEntity()).toList();
  }

  @override
  Future<List<AvailableTripData>> getAvailableTrips(
    BookingSearchQuery query,
  ) async {
    final models = await _searchDatasource.getAvailableTrips(query);
    return models.map((trip) => trip.toEntity()).toList();
  }

  @override
  Future<List<MapPinOption>> getPickupMapPins() async {
    final models = await _searchDatasource.getPickupMapPins();
    return models.map((pin) => pin.toEntity()).toList();
  }

  @override
  Future<List<MapPinOption>> getDestinationMapPins() async {
    final models = await _searchDatasource.getDestinationMapPins();
    return models.map((pin) => pin.toEntity()).toList();
  }

  @override
  Future<List<VehicleDetailData>> getVehicles({String? routeId}) async {
    final models = await _vehicleDatasource.getVehicles(routeId: routeId);
    return models;
  }

  @override
  Future<VehicleDetailData?> getVehicleById(String id) async {
    final model = await _vehicleDatasource.getVehicleById(id);
    return model;
  }
}
