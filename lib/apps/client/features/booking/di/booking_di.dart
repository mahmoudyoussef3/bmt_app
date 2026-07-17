// GENERATED_PLACEHOLDER_HEADER
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bmt_app/apps/client/features/booking/data/datasources/booking_search_datasource.dart';
import 'package:bmt_app/apps/client/features/booking/data/datasources/daily_booking_datasource.dart';
import 'package:bmt_app/apps/client/features/booking/data/datasources/supabase_booking_search_datasource.dart';
import 'package:bmt_app/apps/client/features/booking/data/datasources/supabase_daily_booking_datasource.dart';
import 'package:bmt_app/apps/client/features/booking/data/datasources/supabase_vehicle_booking_datasource.dart';
import 'package:bmt_app/apps/client/features/booking/data/datasources/vehicle_booking_datasource.dart';
import 'package:bmt_app/apps/client/features/booking/data/repositories/booking_repository_impl.dart';
import 'package:bmt_app/apps/client/features/booking/domain/repositories/booking_repository.dart';
import 'package:bmt_app/apps/client/features/booking/domain/usecases/get_available_trips_usecase.dart';
import 'package:bmt_app/apps/client/features/booking/domain/usecases/get_booking_hub_data_usecase.dart';
import 'package:bmt_app/apps/client/features/booking/domain/usecases/get_booking_routes_usecase.dart';
import 'package:bmt_app/apps/client/features/booking/domain/usecases/get_daily_booking_data_usecase.dart';
import 'package:bmt_app/apps/client/features/booking/domain/usecases/get_map_pins_usecase.dart';
import 'package:bmt_app/apps/client/features/booking/domain/usecases/get_popular_routes_usecase.dart';
import 'package:bmt_app/apps/client/features/booking/domain/usecases/get_search_options_usecase.dart';
import 'package:bmt_app/apps/client/features/booking/domain/usecases/get_vehicle_details_usecase.dart';
import 'package:bmt_app/apps/client/features/booking/domain/usecases/get_vehicles_usecase.dart';
import 'package:bmt_app/apps/client/features/booking/domain/usecases/sort_vehicles_usecase.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_cubit.dart';

/// Registers the booking feature's data sources, repositories, use
/// cases and cubits. Idempotent: safe to call more than once.
void registerBookingDependencies(GetIt getIt) {
  if (!getIt.isRegistered<BookingSearchDatasource>()) {
    getIt.registerLazySingleton<BookingSearchDatasource>(
      () => SupabaseBookingSearchDatasource(Supabase.instance.client),
    );
  }

  if (!getIt.isRegistered<DailyBookingDatasource>()) {
    getIt.registerLazySingleton<DailyBookingDatasource>(
      () => SupabaseDailyBookingDatasource(Supabase.instance.client),
    );
  }

  if (!getIt.isRegistered<VehicleBookingDatasource>()) {
    getIt.registerLazySingleton<VehicleBookingDatasource>(
      () => SupabaseVehicleBookingDatasource(Supabase.instance.client),
    );
  }

  if (!getIt.isRegistered<BookingRepository>()) {
    getIt.registerLazySingleton<BookingRepository>(
      () => BookingRepositoryImpl(
        searchDatasource: getIt<BookingSearchDatasource>(),
        dailyBookingDatasource: getIt<DailyBookingDatasource>(),
        vehicleDatasource: getIt<VehicleBookingDatasource>(),
      ),
    );
  }

  if (!getIt.isRegistered<GetBookingHubDataUseCase>()) {
    getIt.registerLazySingleton<GetBookingHubDataUseCase>(
      () => GetBookingHubDataUseCase(getIt<BookingRepository>()),
    );
  }

  if (!getIt.isRegistered<GetDailyBookingDataUseCase>()) {
    getIt.registerLazySingleton<GetDailyBookingDataUseCase>(
      () => GetDailyBookingDataUseCase(getIt<BookingRepository>()),
    );
  }

  if (!getIt.isRegistered<GetBookingRoutesUseCase>()) {
    getIt.registerLazySingleton<GetBookingRoutesUseCase>(
      () => GetBookingRoutesUseCase(getIt<BookingRepository>()),
    );
  }

  if (!getIt.isRegistered<GetPopularRoutesUseCase>()) {
    getIt.registerLazySingleton<GetPopularRoutesUseCase>(
      () => GetPopularRoutesUseCase(getIt<BookingRepository>()),
    );
  }

  if (!getIt.isRegistered<GetMapPinsUseCase>()) {
    getIt.registerLazySingleton<GetMapPinsUseCase>(
      () => GetMapPinsUseCase(getIt<BookingRepository>()),
    );
  }

  if (!getIt.isRegistered<GetSearchOptionsUseCase>()) {
    getIt.registerLazySingleton<GetSearchOptionsUseCase>(
      () => GetSearchOptionsUseCase(getIt<BookingRepository>()),
    );
  }

  if (!getIt.isRegistered<GetAvailableTripsUseCase>()) {
    getIt.registerLazySingleton<GetAvailableTripsUseCase>(
      () => GetAvailableTripsUseCase(getIt<BookingRepository>()),
    );
  }

  if (!getIt.isRegistered<GetVehiclesUseCase>()) {
    getIt.registerLazySingleton<GetVehiclesUseCase>(
      () => GetVehiclesUseCase(getIt<BookingRepository>()),
    );
  }

  if (!getIt.isRegistered<GetVehicleDetailsUseCase>()) {
    getIt.registerLazySingleton<GetVehicleDetailsUseCase>(
      () => GetVehicleDetailsUseCase(getIt<BookingRepository>()),
    );
  }

  if (!getIt.isRegistered<SortVehiclesUseCase>()) {
    getIt.registerLazySingleton<SortVehiclesUseCase>(
      () => const SortVehiclesUseCase(),
    );
  }

  if (!getIt.isRegistered<BookingCubit>()) {
    getIt.registerFactory<BookingCubit>(
      () => BookingCubit(
        getBookingHubData: getIt<GetBookingHubDataUseCase>(),
        getDailyBookingData: getIt<GetDailyBookingDataUseCase>(),
        getRoutes: getIt<GetBookingRoutesUseCase>(),
        getPopularRoutes: getIt<GetPopularRoutesUseCase>(),
        getMapPins: getIt<GetMapPinsUseCase>(),
        getSearchOptions: getIt<GetSearchOptionsUseCase>(),
        getVehicles: getIt<GetVehiclesUseCase>(),
        getVehicleDetails: getIt<GetVehicleDetailsUseCase>(),
        sortVehicles: getIt<SortVehiclesUseCase>(),
      ),
    );
  }
}
