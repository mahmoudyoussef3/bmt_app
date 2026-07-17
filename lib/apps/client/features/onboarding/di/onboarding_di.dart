// GENERATED_PLACEHOLDER_HEADER
import 'package:get_it/get_it.dart';

import 'package:bmt_app/apps/client/features/onboarding/data/datasources/onboarding_local_datasource.dart';
import 'package:bmt_app/apps/client/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:bmt_app/apps/client/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:bmt_app/apps/client/features/onboarding/domain/usecases/check_onboarding_status_usecase.dart';
import 'package:bmt_app/apps/client/features/onboarding/domain/usecases/complete_onboarding_usecase.dart';
import 'package:bmt_app/apps/client/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:bmt_app/core/security/secure_storage.dart';

/// Registers the onboarding feature's data sources, repositories, use
/// cases and cubits. Idempotent: safe to call more than once.
void registerOnboardingDependencies(GetIt getIt) {
  if (!getIt.isRegistered<OnboardingLocalDataSource>()) {
    getIt.registerLazySingleton<OnboardingLocalDataSource>(
      () => OnboardingLocalDataSourceImpl(SecureStorage()),
    );
  }

  if (!getIt.isRegistered<OnboardingRepository>()) {
    getIt.registerLazySingleton<OnboardingRepository>(
      () => OnboardingRepositoryImpl(getIt<OnboardingLocalDataSource>()),
    );
  }

  if (!getIt.isRegistered<CheckOnboardingStatusUseCase>()) {
    getIt.registerLazySingleton<CheckOnboardingStatusUseCase>(
      () => CheckOnboardingStatusUseCase(getIt<OnboardingRepository>()),
    );
  }

  if (!getIt.isRegistered<CompleteOnboardingUseCase>()) {
    getIt.registerLazySingleton<CompleteOnboardingUseCase>(
      () => CompleteOnboardingUseCase(getIt<OnboardingRepository>()),
    );
  }

  if (!getIt.isRegistered<OnboardingCubit>()) {
    getIt.registerFactory<OnboardingCubit>(
      () => OnboardingCubit(
        getIt<CheckOnboardingStatusUseCase>(),
        getIt<CompleteOnboardingUseCase>(),
      ),
    );
  }
}
