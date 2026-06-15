import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/booking_search_query.dart';
import '../../domain/entities/vehicle_detail.dart';
import '../../domain/usecases/get_booking_hub_data_usecase.dart';
import '../../domain/usecases/get_booking_routes_usecase.dart';
import '../../domain/usecases/get_daily_booking_data_usecase.dart';
import '../../domain/usecases/get_map_pins_usecase.dart';
import '../../domain/usecases/get_popular_routes_usecase.dart';
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
    required GetVehiclesUseCase getVehicles,
    required GetVehicleDetailsUseCase getVehicleDetails,
    required SortVehiclesUseCase sortVehicles,
  }) : _getBookingHubData = getBookingHubData,
       _getDailyBookingData = getDailyBookingData,
       _getRoutes = getRoutes,
       _getPopularRoutes = getPopularRoutes,
       _getMapPins = getMapPins,
       _getVehicles = getVehicles,
       _getVehicleDetails = getVehicleDetails,
       _sortVehicles = sortVehicles,
       super(const BookingLoading());

  final GetBookingHubDataUseCase _getBookingHubData;
  final GetDailyBookingDataUseCase _getDailyBookingData;
  final GetBookingRoutesUseCase _getRoutes;
  final GetPopularRoutesUseCase _getPopularRoutes;
  final GetMapPinsUseCase _getMapPins;
  final GetVehiclesUseCase _getVehicles;
  final GetVehicleDetailsUseCase _getVehicleDetails;
  final SortVehiclesUseCase _sortVehicles;

  Future<void> loadBookingHubData() async {
    emit(const BookingLoading());
    try {
      final data = await _getBookingHubData();
      emit(BookingHubLoaded(data));
    } catch (error) {
      emit(BookingError(error.toString()));
    }
  }

  Future<void> loadDailyBookingData() async {
    emit(const BookingLoading());
    try {
      final data = await _getDailyBookingData();
      emit(DailyBookingLoaded(data));
    } catch (error) {
      emit(BookingError(error.toString()));
    }
  }

  Future<void> loadRoutes(BookingSearchQuery query) async {
    emit(const BookingLoading());
    try {
      final routes = await _getRoutes(query);
      emit(BookingRoutesLoaded(routes));
    } catch (error) {
      emit(BookingError(error.toString()));
    }
  }

  Future<void> loadPopularRoutes() async {
    emit(const BookingLoading());
    try {
      final routes = await _getPopularRoutes();
      emit(PopularRoutesLoaded(routes));
    } catch (error) {
      emit(BookingError(error.toString()));
    }
  }

  Future<void> loadMapPins() async {
    emit(const BookingLoading());
    try {
      final pins = await _getMapPins();
      emit(MapPinsLoaded(pickup: pins.pickup, destination: pins.destination));
    } catch (error) {
      emit(BookingError(error.toString()));
    }
  }

  Future<void> loadVehicles({
    VehicleSortOption sort = VehicleSortOption.recommended,
    String? routeId,
  }) async {
    emit(const BookingLoading());
    try {
      final vehicles = await _getVehicles(routeId: routeId);
      emit(VehiclesLoaded(_sortVehicles(vehicles, sort)));
    } catch (error) {
      emit(BookingError(error.toString()));
    }
  }

  Future<void> loadVehicleDetails(String? id) async {
    emit(const BookingLoading());
    try {
      final vehicle = id == null || id.isEmpty
          ? (await _getVehicles()).firstOrNull
          : await _getVehicleDetails(id);
      emit(VehicleDetailsLoaded(vehicle));
    } catch (error) {
      emit(BookingError(error.toString()));
    }
  }
}
