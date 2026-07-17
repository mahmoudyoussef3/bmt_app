// GENERATED_PLACEHOLDER_HEADER
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bmt_app/apps/client/features/trips/data/datasources/supabase_trip_reviews_datasource.dart';
import 'package:bmt_app/apps/client/features/trips/data/datasources/supabase_trips_datasource.dart';
import 'package:bmt_app/apps/client/features/trips/data/datasources/trip_reviews_datasource.dart';
import 'package:bmt_app/apps/client/features/trips/data/datasources/trips_datasource.dart';
import 'package:bmt_app/apps/client/features/trips/data/repositories/trip_reviews_repository_impl.dart';
import 'package:bmt_app/apps/client/features/trips/data/repositories/trips_repository_impl.dart';
import 'package:bmt_app/apps/client/features/trips/domain/repositories/trip_reviews_repository.dart';
import 'package:bmt_app/apps/client/features/trips/domain/repositories/trips_repository.dart';
import 'package:bmt_app/apps/client/features/trips/domain/usecases/cancel_booking_usecase.dart';
import 'package:bmt_app/apps/client/features/trips/domain/usecases/get_trip_details_usecase.dart';
import 'package:bmt_app/apps/client/features/trips/domain/usecases/get_trip_review_usecase.dart';
import 'package:bmt_app/apps/client/features/trips/domain/usecases/get_trips_usecase.dart';
import 'package:bmt_app/apps/client/features/trips/domain/usecases/submit_trip_review_usecase.dart';
import 'package:bmt_app/apps/client/features/trips/domain/usecases/watch_trips_usecase.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/cubit/trip_review_cubit.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/cubit/trips_cubit.dart';

/// Registers the trips feature's data sources, repositories, use
/// cases and cubits. Idempotent: safe to call more than once.
void registerTripsDependencies(GetIt getIt) {
  if (!getIt.isRegistered<TripsDatasource>()) {
    getIt.registerLazySingleton<TripsDatasource>(
      () => SupabaseTripsDatasource(Supabase.instance.client),
    );
  }

  if (!getIt.isRegistered<TripsRepository>()) {
    getIt.registerLazySingleton<TripsRepository>(
      () => TripsRepositoryImpl(getIt<TripsDatasource>()),
    );
  }

  if (!getIt.isRegistered<GetTripsUseCase>()) {
    getIt.registerLazySingleton<GetTripsUseCase>(
      () => GetTripsUseCase(getIt<TripsRepository>()),
    );
  }

  if (!getIt.isRegistered<GetTripDetailsUseCase>()) {
    getIt.registerLazySingleton<GetTripDetailsUseCase>(
      () => GetTripDetailsUseCase(getIt<TripsRepository>()),
    );
  }

  if (!getIt.isRegistered<WatchTripsUseCase>()) {
    getIt.registerLazySingleton<WatchTripsUseCase>(
      () => WatchTripsUseCase(getIt<TripsRepository>()),
    );
  }

  if (!getIt.isRegistered<CancelBookingUseCase>()) {
    getIt.registerLazySingleton<CancelBookingUseCase>(
      () => CancelBookingUseCase(getIt<TripsRepository>()),
    );
  }

  if (!getIt.isRegistered<TripsCubit>()) {
    getIt.registerFactory<TripsCubit>(
      () => TripsCubit(
        getTrips: getIt<GetTripsUseCase>(),
        getTripDetails: getIt<GetTripDetailsUseCase>(),
        watchTrips: getIt<WatchTripsUseCase>(),
        cancelBooking: getIt<CancelBookingUseCase>(),
      ),
    );
  }
  _registerTripReviewDependencies(getIt);
}

void _registerTripReviewDependencies(GetIt getIt) {
  if (!getIt.isRegistered<TripReviewsDatasource>()) {
    getIt.registerLazySingleton<TripReviewsDatasource>(
      () => SupabaseTripReviewsDatasource(Supabase.instance.client),
    );
  }

  if (!getIt.isRegistered<TripReviewsRepository>()) {
    getIt.registerLazySingleton<TripReviewsRepository>(
      () => TripReviewsRepositoryImpl(getIt<TripReviewsDatasource>()),
    );
  }

  if (!getIt.isRegistered<GetTripReviewUseCase>()) {
    getIt.registerLazySingleton<GetTripReviewUseCase>(
      () => GetTripReviewUseCase(getIt<TripReviewsRepository>()),
    );
  }

  if (!getIt.isRegistered<SubmitTripReviewUseCase>()) {
    getIt.registerLazySingleton<SubmitTripReviewUseCase>(
      () => SubmitTripReviewUseCase(getIt<TripReviewsRepository>()),
    );
  }

  if (!getIt.isRegistered<TripReviewCubit>()) {
    getIt.registerFactory<TripReviewCubit>(
      () => TripReviewCubit(
        getReview: getIt<GetTripReviewUseCase>(),
        submitReview: getIt<SubmitTripReviewUseCase>(),
      ),
    );
  }
}
