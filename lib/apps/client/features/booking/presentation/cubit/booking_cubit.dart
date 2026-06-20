import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/booking_hub_data.dart';
import '../../domain/entities/booking_option.dart';
import '../../domain/entities/booking_search_query.dart';
import '../../domain/entities/daily_booking_data.dart';
import '../../domain/entities/search_options.dart';
import '../../domain/entities/vehicle_detail.dart';
import '../../domain/usecases/get_booking_hub_data_usecase.dart';
import '../../domain/usecases/get_booking_routes_usecase.dart';
import '../../domain/usecases/get_daily_booking_data_usecase.dart';
import '../../domain/usecases/get_map_pins_usecase.dart';
import '../../domain/usecases/get_popular_routes_usecase.dart';
import '../../domain/usecases/get_search_options_usecase.dart';
import '../../domain/usecases/get_vehicle_details_usecase.dart';
import '../../domain/usecases/get_vehicles_usecase.dart';
import '../../domain/usecases/sort_vehicles_usecase.dart';
import 'booking_state.dart';

class BookingCubit extends Cubit<BookingState> {
  BookingCubit({
    required GetBookingHubDataUseCase getBookingHubData,
    required GetDailyBookingDataUseCase getDailyBookingData,
    required GetBookingRoutesUseCase getRoutes,
    required GetPopularRoutesUseCase getPopularRoutes,
    required GetMapPinsUseCase getMapPins,
    required GetSearchOptionsUseCase getSearchOptions,
    required GetVehiclesUseCase getVehicles,
    required GetVehicleDetailsUseCase getVehicleDetails,
    required SortVehiclesUseCase sortVehicles,
  }) : _getBookingHubData = getBookingHubData,
       _getDailyBookingData = getDailyBookingData,
       _getRoutes = getRoutes,
       _getPopularRoutes = getPopularRoutes,
       _getMapPins = getMapPins,
       _getSearchOptions = getSearchOptions,
       _getVehicles = getVehicles,
       _getVehicleDetails = getVehicleDetails,
       _sortVehicles = sortVehicles,
       super(const BookingLoading());

  final GetBookingHubDataUseCase _getBookingHubData;
  final GetDailyBookingDataUseCase _getDailyBookingData;
  final GetBookingRoutesUseCase _getRoutes;
  final GetPopularRoutesUseCase _getPopularRoutes;
  final GetMapPinsUseCase _getMapPins;
  final GetSearchOptionsUseCase _getSearchOptions;
  final GetVehiclesUseCase _getVehicles;
  final GetVehicleDetailsUseCase _getVehicleDetails;
  final SortVehiclesUseCase _sortVehicles;

  BookingHubData? _bookingHubCache;
  DailyBookingData? _dailyBookingCache;
  TripSearchOptions? _searchOptionsCache;
  List<PopularRouteListData>? _popularRoutesCache;
  List<MapPinOption>? _pickupPinsCache;
  List<MapPinOption>? _destinationPinsCache;
  final Map<String, List<RouteOptionData>> _routesCache = {};
  final Map<String, List<VehicleDetailData>> _vehiclesCache = {};
  final Map<String, VehicleDetailData?> _vehicleDetailsCache = {};

  bool _bookingHubLoading = false;
  bool _dailyBookingLoading = false;
  bool _searchOptionsLoading = false;
  bool _popularRoutesLoading = false;
  bool _mapPinsLoading = false;
  final Set<String> _routesLoadingKeys = {};
  final Set<String> _vehiclesLoadingKeys = {};
  final Set<String> _vehicleDetailsLoadingKeys = {};

  Future<void> loadBookingHubData({bool force = false}) async {
    if (!force && _bookingHubCache != null) {
      emit(BookingHubLoaded(_bookingHubCache!));
      return;
    }
    if (_bookingHubLoading) return;
    _bookingHubLoading = true;
    emit(const BookingLoading());
    try {
      final data = await _getBookingHubData();
      _bookingHubCache = data;
      emit(BookingHubLoaded(data));
    } catch (error) {
      emit(BookingError(error.toString()));
    } finally {
      _bookingHubLoading = false;
    }
  }

  Future<void> loadDailyBookingData({bool force = false}) async {
    if (!force && _dailyBookingCache != null) {
      emit(DailyBookingLoaded(_dailyBookingCache!));
      return;
    }
    if (_dailyBookingLoading) return;
    _dailyBookingLoading = true;
    emit(const BookingLoading());
    try {
      final data = await _getDailyBookingData();
      _dailyBookingCache = data;
      emit(DailyBookingLoaded(data));
    } catch (error) {
      emit(BookingError(error.toString()));
    } finally {
      _dailyBookingLoading = false;
    }
  }

  Future<void> loadRoutes(
    BookingSearchQuery query, {
    bool force = false,
  }) async {
    final key = _queryKey(query);
    final cached = _routesCache[key];
    if (!force && cached != null) {
      emit(BookingRoutesLoaded(cached));
      return;
    }
    if (_routesLoadingKeys.contains(key)) return;
    _routesLoadingKeys.add(key);
    emit(const BookingLoading());
    try {
      final routes = await _getRoutes(query);
      _routesCache[key] = routes;
      emit(BookingRoutesLoaded(routes));
    } catch (error) {
      emit(BookingError(error.toString()));
    } finally {
      _routesLoadingKeys.remove(key);
    }
  }

  Future<void> loadPopularRoutes({bool force = false}) async {
    if (!force && _popularRoutesCache != null) {
      emit(PopularRoutesLoaded(_popularRoutesCache!));
      return;
    }
    if (_popularRoutesLoading) return;
    _popularRoutesLoading = true;
    emit(const BookingLoading());
    try {
      final routes = await _getPopularRoutes();
      _popularRoutesCache = routes;
      emit(PopularRoutesLoaded(routes));
    } catch (error) {
      emit(BookingError(error.toString()));
    } finally {
      _popularRoutesLoading = false;
    }
  }

  Future<void> loadMapPins({bool force = false}) async {
    if (!force && _pickupPinsCache != null && _destinationPinsCache != null) {
      emit(
        MapPinsLoaded(
          pickup: _pickupPinsCache!,
          destination: _destinationPinsCache!,
        ),
      );
      return;
    }
    if (_mapPinsLoading) return;
    _mapPinsLoading = true;
    emit(const BookingLoading());
    try {
      final pins = await _getMapPins();
      _pickupPinsCache = pins.pickup;
      _destinationPinsCache = pins.destination;
      emit(MapPinsLoaded(pickup: pins.pickup, destination: pins.destination));
    } catch (error) {
      emit(BookingError(error.toString()));
    } finally {
      _mapPinsLoading = false;
    }
  }

  Future<void> loadSearchOptions({bool force = false}) async {
    if (!force && _searchOptionsCache != null) {
      emit(SearchOptionsLoaded(_searchOptionsCache!));
      return;
    }
    if (_searchOptionsLoading) return;
    _searchOptionsLoading = true;
    emit(const BookingLoading());
    try {
      final options = await _getSearchOptions();
      _searchOptionsCache = options;
      emit(SearchOptionsLoaded(options));
    } catch (error) {
      emit(BookingError(error.toString()));
    } finally {
      _searchOptionsLoading = false;
    }
  }

  Future<void> loadVehicles({
    VehicleSortOption sort = VehicleSortOption.recommended,
    String? routeId,
    bool force = false,
  }) async {
    final key = _routeKey(routeId);
    final cached = _vehiclesCache[key];
    if (!force && cached != null) {
      emit(VehiclesLoaded(_sortVehicles(cached, sort)));
      return;
    }
    if (_vehiclesLoadingKeys.contains(key)) return;
    _vehiclesLoadingKeys.add(key);
    emit(const BookingLoading());
    try {
      final vehicles = await _getVehicles(routeId: routeId);
      _vehiclesCache[key] = vehicles;
      emit(VehiclesLoaded(_sortVehicles(vehicles, sort)));
    } catch (error) {
      emit(BookingError(error.toString()));
    } finally {
      _vehiclesLoadingKeys.remove(key);
    }
  }

  Future<void> loadVehicleDetails(String? id, {bool force = false}) async {
    final key = _routeKey(id);
    if (!force && _vehicleDetailsCache.containsKey(key)) {
      emit(VehicleDetailsLoaded(_vehicleDetailsCache[key]));
      return;
    }
    if (_vehicleDetailsLoadingKeys.contains(key)) return;
    _vehicleDetailsLoadingKeys.add(key);
    emit(const BookingLoading());
    try {
      final vehicle = id == null || id.isEmpty
          ? (await _getVehicles()).firstOrNull
          : await _getVehicleDetails(id);
      _vehicleDetailsCache[key] = vehicle;
      emit(VehicleDetailsLoaded(vehicle));
    } catch (error) {
      emit(BookingError(error.toString()));
    } finally {
      _vehicleDetailsLoadingKeys.remove(key);
    }
  }

  String _queryKey(BookingSearchQuery query) {
    return [
      query.routeId ?? '',
      query.pickup.trim(),
      query.destination.trim(),
      query.date.trim(),
      query.time.trim(),
    ].join('|');
  }

  String _routeKey(String? value) =>
      value?.trim().isNotEmpty == true ? value!.trim() : '__all__';
}
