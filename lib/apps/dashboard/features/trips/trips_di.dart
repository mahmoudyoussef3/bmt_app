import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/session/dashboard_session.dart';

import 'trip_management/data/datasources/trips_datasource.dart';
import 'trip_management/data/datasources/supabase_trips_datasource.dart';

import 'trip_management/domain/repositories/trips_repository.dart';
import 'trip_management/data/repositories/trips_repository_impl.dart';

import 'trip_management/domain/usecases/trip_management_usecases.dart';
import 'trip_creation/domain/usecases/trip_creation_usecases.dart';
import 'trip_seats/domain/usecases/trip_seats_usecases.dart';
import 'trip_pricing/domain/usecases/trip_pricing_usecases.dart';
import 'trip_passengers/domain/usecases/trip_passengers_usecases.dart';
import 'trip_events/domain/usecases/trip_events_usecases.dart';

import 'trip_management/presentation/cubit/trips_list_cubit.dart';
import 'trip_management/presentation/cubit/trip_details_cubit.dart';
import 'trip_creation/presentation/cubit/trip_creation_cubit.dart';
import 'trip_seats/presentation/cubit/trip_seats_cubit.dart';
import 'trip_pricing/presentation/cubit/trip_pricing_cubit.dart';
import 'trip_passengers/presentation/cubit/trip_passengers_cubit.dart';

void registerTripsDependencies(GetIt di) {
  
  di.registerLazySingleton<TripsDatasource>(
    () => SupabaseTripsDatasource(di<SupabaseClient>(), di<DashboardSession>()),
  );

  di.registerLazySingleton<TripsRepository>(
    () => TripsRepositoryImpl(di<TripsDatasource>()),
  );

  di.registerLazySingleton(
    () => GetOperationTripsUseCase(di<TripsRepository>()),
  );
  di.registerLazySingleton(() => GetTripDetailsUseCase(di<TripsRepository>()));
  di.registerLazySingleton(
    () => UpdateTripStatusUseCase(di<TripsRepository>()),
  );
  di.registerLazySingleton(() => UpdateTripInfoUseCase(di<TripsRepository>()));
  di.registerLazySingleton(() => CancelTripUseCase(di<TripsRepository>()));
  di.registerLazySingleton(() => CloseStaleTripUseCase(di<TripsRepository>()));
  di.registerLazySingleton(() => DeleteTripUseCase(di<TripsRepository>()));
  di.registerLazySingleton(
    () => WatchOperationTripsUseCase(di<TripsRepository>()),
  );
  di.registerLazySingleton(
    () => WatchTripDetailsUseCase(di<TripsRepository>()),
  );

  di.registerLazySingleton(() => CreateTripUseCase(di<TripsRepository>()));
  di.registerLazySingleton(() => GetActiveRoutesUseCase(di<TripsRepository>()));
  di.registerLazySingleton(
    () => GetActiveDriversUseCase(di<TripsRepository>()),
  );
  di.registerLazySingleton(
    () => GetResourceConflictsUseCase(di<TripsRepository>()),
  );
  di.registerLazySingleton(
    () => GetOfficePricablePackagesUseCase(di<TripsRepository>()),
  );

  di.registerLazySingleton(() => UpdateSeatStateUseCase(di<TripsRepository>()));

  di.registerLazySingleton(() => GetTripPricingUseCase(di<TripsRepository>()));
  di.registerLazySingleton(() => SaveTripPricingUseCase(di<TripsRepository>()));
  di.registerLazySingleton(
    () => ToggleTripPricingUseCase(di<TripsRepository>()),
  );

  di.registerLazySingleton(() => UpdatePassengerUseCase(di<TripsRepository>()));
  di.registerLazySingleton(() => CancelPassengerUseCase(di<TripsRepository>()));
  di.registerLazySingleton(() => MovePassengerUseCase(di<TripsRepository>()));

  di.registerLazySingleton(() => GetTripEventsUseCase(di<TripsRepository>()));

  di.registerFactory(
    () => TripsListCubit(
      di<GetOperationTripsUseCase>(),
      di<DeleteTripUseCase>(),
      di<WatchOperationTripsUseCase>(),
    ),
  );
  di.registerFactory(
    () => TripDetailsCubit(
      getTripDetails: di<GetTripDetailsUseCase>(),
      updateTripStatus: di<UpdateTripStatusUseCase>(),
      updateTripInfo: di<UpdateTripInfoUseCase>(),
      cancelTrip: di<CancelTripUseCase>(),
      closeStaleTrip: di<CloseStaleTripUseCase>(),
      watchTripDetails: di<WatchTripDetailsUseCase>(),
    ),
  );
  di.registerFactory(
    () => TripCreationCubit(
      createTrip: di<CreateTripUseCase>(),
      getActiveRoutes: di<GetActiveRoutesUseCase>(),
      getActiveDrivers: di<GetActiveDriversUseCase>(),
      getResourceConflicts: di<GetResourceConflictsUseCase>(),
      getPricablePackages: di<GetOfficePricablePackagesUseCase>(),
    ),
  );
  di.registerFactory(() => TripSeatsCubit(di<UpdateSeatStateUseCase>()));
  di.registerFactory(
    () => TripPricingCubit(
      getTripPricing: di<GetTripPricingUseCase>(),
      saveTripPricing: di<SaveTripPricingUseCase>(),
      toggleTripPricing: di<ToggleTripPricingUseCase>(),
      getPricablePackages: di<GetOfficePricablePackagesUseCase>(),
    ),
  );
  di.registerFactory(
    () => TripPassengersCubit(
      updatePassenger: di<UpdatePassengerUseCase>(),
      cancelPassenger: di<CancelPassengerUseCase>(),
      movePassenger: di<MovePassengerUseCase>(),
    ),
  );
}
