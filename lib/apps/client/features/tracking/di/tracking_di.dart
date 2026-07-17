// GENERATED_PLACEHOLDER_HEADER
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bmt_app/apps/client/features/tracking/data/datasources/supabase_tracking_datasource.dart';
import 'package:bmt_app/apps/client/features/tracking/data/repositories/tracking_repository_impl.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/usecases/get_tracking_trip_usecase.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/usecases/watch_tracking_trip_usecase.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/usecases/watch_vehicle_position_usecase.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/cubit/tracking_cubit.dart';

/// Registers the tracking feature's data sources, repositories, use
/// cases and cubits. Idempotent: safe to call more than once.
void registerTrackingDependencies(GetIt getIt) {
  if (!getIt.isRegistered<SupabaseTrackingDatasource>()) {
    getIt.registerLazySingleton<SupabaseTrackingDatasource>(
      () => SupabaseTrackingDatasource(Supabase.instance.client),
    );
  }

  if (!getIt.isRegistered<TrackingRepository>()) {
    getIt.registerLazySingleton<TrackingRepository>(
      () => TrackingRepositoryImpl(getIt<SupabaseTrackingDatasource>()),
    );
  }

  if (!getIt.isRegistered<GetTrackingTripUseCase>()) {
    getIt.registerLazySingleton<GetTrackingTripUseCase>(
      () => GetTrackingTripUseCase(getIt<TrackingRepository>()),
    );
  }

  if (!getIt.isRegistered<WatchVehiclePositionUseCase>()) {
    getIt.registerLazySingleton<WatchVehiclePositionUseCase>(
      () => WatchVehiclePositionUseCase(getIt<TrackingRepository>()),
    );
  }

  if (!getIt.isRegistered<WatchTrackingTripUseCase>()) {
    getIt.registerLazySingleton<WatchTrackingTripUseCase>(
      () => WatchTrackingTripUseCase(getIt<TrackingRepository>()),
    );
  }

  if (!getIt.isRegistered<TrackingCubit>()) {
    getIt.registerFactory<TrackingCubit>(
      () => TrackingCubit(
        getTrackingTrip: getIt<GetTrackingTripUseCase>(),
        watchVehiclePosition: getIt<WatchVehiclePositionUseCase>(),
        watchTrackingTrip: getIt<WatchTrackingTripUseCase>(),
      ),
    );
  }
}
