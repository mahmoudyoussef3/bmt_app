// GENERATED_PLACEHOLDER_HEADER
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bmt_app/apps/client/features/profile/data/datasources/profile_datasource.dart';
import 'package:bmt_app/apps/client/features/profile/data/datasources/supabase_profile_datasource.dart';
import 'package:bmt_app/apps/client/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:bmt_app/apps/client/features/profile/domain/repositories/profile_repository.dart';
import 'package:bmt_app/apps/client/features/profile/domain/usecases/get_profile_data_usecase.dart';
import 'package:bmt_app/apps/client/features/profile/domain/usecases/update_profile_usecase.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/cubit/profile_cubit.dart';

/// Registers the profile feature's data sources, repositories, use
/// cases and cubits. Idempotent: safe to call more than once.
void registerProfileDependencies(GetIt getIt) {
  if (!getIt.isRegistered<ProfileDatasource>()) {
    getIt.registerLazySingleton<ProfileDatasource>(
      () => SupabaseProfileDatasource(Supabase.instance.client),
    );
  }

  if (!getIt.isRegistered<ProfileRepository>()) {
    getIt.registerLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(getIt<ProfileDatasource>()),
    );
  }

  if (!getIt.isRegistered<GetProfileDataUseCase>()) {
    getIt.registerLazySingleton<GetProfileDataUseCase>(
      () => GetProfileDataUseCase(getIt<ProfileRepository>()),
    );
  }

  if (!getIt.isRegistered<UpdateProfileUseCase>()) {
    getIt.registerLazySingleton<UpdateProfileUseCase>(
      () => UpdateProfileUseCase(getIt<ProfileRepository>()),
    );
  }

  if (!getIt.isRegistered<ProfileCubit>()) {
    getIt.registerFactory<ProfileCubit>(
      () => ProfileCubit(
        getIt<GetProfileDataUseCase>(),
        getIt<UpdateProfileUseCase>(),
      ),
    );
  }
}
