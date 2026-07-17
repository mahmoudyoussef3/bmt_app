// GENERATED_PLACEHOLDER_HEADER
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bmt_app/apps/client/features/routes/data/datasources/supabase_routes_hub_datasource.dart';
import 'package:bmt_app/apps/client/features/routes/data/repositories/routes_hub_repository_impl.dart';
import 'package:bmt_app/apps/client/features/routes/domain/repositories/routes_hub_repository.dart';
import 'package:bmt_app/apps/client/features/routes/domain/usecases/get_routes_hub_data_usecase.dart';
import 'package:bmt_app/apps/client/features/routes/presentation/cubit/routes_hub_cubit.dart';

/// Registers the routes feature's data sources, repositories, use
/// cases and cubits. Idempotent: safe to call more than once.
void registerRoutesHubDependencies(GetIt getIt) {
  if (!getIt.isRegistered<SupabaseRoutesHubDatasource>()) {
    getIt.registerLazySingleton<SupabaseRoutesHubDatasource>(
      () => SupabaseRoutesHubDatasource(Supabase.instance.client),
    );
  }

  if (!getIt.isRegistered<RoutesHubRepository>()) {
    getIt.registerLazySingleton<RoutesHubRepository>(
      () => RoutesHubRepositoryImpl(getIt<SupabaseRoutesHubDatasource>()),
    );
  }

  if (!getIt.isRegistered<GetRoutesHubDataUseCase>()) {
    getIt.registerLazySingleton<GetRoutesHubDataUseCase>(
      () => GetRoutesHubDataUseCase(getIt<RoutesHubRepository>()),
    );
  }

  if (!getIt.isRegistered<RoutesHubCubit>()) {
    getIt.registerFactory<RoutesHubCubit>(
      () => RoutesHubCubit(getIt<GetRoutesHubDataUseCase>()),
    );
  }
}
