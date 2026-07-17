// GENERATED_PLACEHOLDER_HEADER
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bmt_app/apps/client/features/seat_release/data/datasources/supabase_seat_release_datasource.dart';
import 'package:bmt_app/apps/client/features/seat_release/data/repositories/seat_release_repository_impl.dart';
import 'package:bmt_app/apps/client/features/seat_release/domain/repositories/seat_release_repository.dart';
import 'package:bmt_app/apps/client/features/seat_release/domain/usecases/get_seat_release_data_usecase.dart';
import 'package:bmt_app/apps/client/features/seat_release/presentation/cubit/seat_release_cubit.dart';

/// Registers the seat_release feature's data sources, repositories, use
/// cases and cubits. Idempotent: safe to call more than once.
void registerSeatReleaseDependencies(GetIt getIt) {
  if (!getIt.isRegistered<SupabaseSeatReleaseDatasource>()) {
    getIt.registerLazySingleton<SupabaseSeatReleaseDatasource>(
      () => SupabaseSeatReleaseDatasource(Supabase.instance.client),
    );
  }

  if (!getIt.isRegistered<SeatReleaseRepository>()) {
    getIt.registerLazySingleton<SeatReleaseRepository>(
      () => SeatReleaseRepositoryImpl(
        getIt<SupabaseSeatReleaseDatasource>(),
      ),
    );
  }

  if (!getIt.isRegistered<GetSeatReleaseDataUseCase>()) {
    getIt.registerLazySingleton<GetSeatReleaseDataUseCase>(
      () => GetSeatReleaseDataUseCase(getIt<SeatReleaseRepository>()),
    );
  }

  if (!getIt.isRegistered<SeatReleaseCubit>()) {
    getIt.registerFactory<SeatReleaseCubit>(
      () => SeatReleaseCubit(getIt<GetSeatReleaseDataUseCase>()),
    );
  }
}
