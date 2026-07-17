// GENERATED_PLACEHOLDER_HEADER
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bmt_app/apps/client/features/home/data/datasources/home_datasource.dart';
import 'package:bmt_app/apps/client/features/home/data/datasources/supabase_home_datasource.dart';
import 'package:bmt_app/apps/client/features/home/data/repositories/home_repository_impl.dart';
import 'package:bmt_app/apps/client/features/home/domain/repositories/home_repository.dart';
import 'package:bmt_app/apps/client/features/home/domain/usecases/get_home_data_usecase.dart';
import 'package:bmt_app/apps/client/features/home/domain/usecases/watch_home_changes_usecase.dart';
import 'package:bmt_app/apps/client/features/home/presentation/cubit/home_cubit.dart';

/// Registers the home feature's data sources, repositories, use
/// cases and cubits. Idempotent: safe to call more than once.
void registerHomeDependencies(GetIt getIt) {
  if (!getIt.isRegistered<HomeDatasource>()) {
    getIt.registerLazySingleton<HomeDatasource>(
      () => SupabaseHomeDatasource(Supabase.instance.client),
    );
  }

  if (!getIt.isRegistered<HomeRepository>()) {
    getIt.registerLazySingleton<HomeRepository>(
      () => HomeRepositoryImpl(getIt<HomeDatasource>()),
    );
  }

  if (!getIt.isRegistered<GetHomeDataUseCase>()) {
    getIt.registerLazySingleton<GetHomeDataUseCase>(
      () => GetHomeDataUseCase(getIt<HomeRepository>()),
    );
  }

  if (!getIt.isRegistered<WatchHomeChangesUseCase>()) {
    getIt.registerLazySingleton<WatchHomeChangesUseCase>(
      () => WatchHomeChangesUseCase(getIt<HomeRepository>()),
    );
  }

  if (!getIt.isRegistered<HomeCubit>()) {
    getIt.registerFactory<HomeCubit>(
      () => HomeCubit(
        getIt<GetHomeDataUseCase>(),
        getIt<WatchHomeChangesUseCase>(),
      ),
    );
  }
}
