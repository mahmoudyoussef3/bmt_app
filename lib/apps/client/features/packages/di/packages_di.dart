// GENERATED_PLACEHOLDER_HEADER
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bmt_app/apps/client/features/packages/data/datasources/packages_datasource.dart';
import 'package:bmt_app/apps/client/features/packages/data/datasources/supabase_packages_datasource.dart';
import 'package:bmt_app/apps/client/features/packages/data/repositories/packages_repository_impl.dart';
import 'package:bmt_app/apps/client/features/packages/domain/repositories/packages_repository.dart';
import 'package:bmt_app/apps/client/features/packages/domain/usecases/calculate_package_pricing_usecase.dart';
import 'package:bmt_app/apps/client/features/packages/domain/usecases/create_subscription_usecase.dart';
import 'package:bmt_app/apps/client/features/packages/domain/usecases/filter_packages_usecase.dart';
import 'package:bmt_app/apps/client/features/packages/domain/usecases/get_package_selection_data_usecase.dart';
import 'package:bmt_app/apps/client/features/packages/presentation/cubit/packages_cubit.dart';

/// Registers the packages feature's data sources, repositories, use
/// cases and cubits. Idempotent: safe to call more than once.
void registerPackagesDependencies(GetIt getIt) {
  if (!getIt.isRegistered<PackagesDatasource>()) {
    getIt.registerLazySingleton<PackagesDatasource>(
      () => SupabasePackagesDatasource(Supabase.instance.client),
    );
  }

  if (!getIt.isRegistered<PackagesRepository>()) {
    getIt.registerLazySingleton<PackagesRepository>(
      () => PackagesRepositoryImpl(getIt<PackagesDatasource>()),
    );
  }

  if (!getIt.isRegistered<GetPackageSelectionDataUseCase>()) {
    getIt.registerLazySingleton<GetPackageSelectionDataUseCase>(
      () => GetPackageSelectionDataUseCase(getIt<PackagesRepository>()),
    );
  }

  if (!getIt.isRegistered<FilterPackagesUseCase>()) {
    getIt.registerLazySingleton<FilterPackagesUseCase>(
      () => const FilterPackagesUseCase(),
    );
  }

  if (!getIt.isRegistered<CalculatePackagePricingUseCase>()) {
    getIt.registerLazySingleton<CalculatePackagePricingUseCase>(
      () => const CalculatePackagePricingUseCase(),
    );
  }

  if (!getIt.isRegistered<CreateSubscriptionUseCase>()) {
    getIt.registerLazySingleton<CreateSubscriptionUseCase>(
      () => CreateSubscriptionUseCase(getIt<PackagesRepository>()),
    );
  }

  if (!getIt.isRegistered<PackagesCubit>()) {
    getIt.registerFactory<PackagesCubit>(
      () => PackagesCubit(
        getSelectionData: getIt<GetPackageSelectionDataUseCase>(),
        filterPackages: getIt<FilterPackagesUseCase>(),
        calculatePricing: getIt<CalculatePackagePricingUseCase>(),
        createSubscription: getIt<CreateSubscriptionUseCase>(),
      ),
    );
  }
}
