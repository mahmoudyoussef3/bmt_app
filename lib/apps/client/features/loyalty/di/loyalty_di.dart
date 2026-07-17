// GENERATED_PLACEHOLDER_HEADER
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bmt_app/apps/client/features/loyalty/data/datasources/loyalty_datasource.dart';
import 'package:bmt_app/apps/client/features/loyalty/data/datasources/supabase_loyalty_datasource.dart';
import 'package:bmt_app/apps/client/features/loyalty/data/repositories/loyalty_repository_impl.dart';
import 'package:bmt_app/apps/client/features/loyalty/domain/repositories/loyalty_repository.dart';
import 'package:bmt_app/apps/client/features/loyalty/domain/usecases/get_loyalty_data_usecase.dart';
import 'package:bmt_app/apps/client/features/loyalty/domain/usecases/redeem_loyalty_reward_usecase.dart';
import 'package:bmt_app/apps/client/features/loyalty/presentation/cubit/loyalty_cubit.dart';

/// Registers the loyalty feature's data sources, repositories, use
/// cases and cubits. Idempotent: safe to call more than once.
void registerLoyaltyDependencies(GetIt getIt) {
  if (!getIt.isRegistered<LoyaltyDatasource>()) {
    getIt.registerLazySingleton<LoyaltyDatasource>(
      () => SupabaseLoyaltyDatasource(Supabase.instance.client),
    );
  }

  if (!getIt.isRegistered<LoyaltyRepository>()) {
    getIt.registerLazySingleton<LoyaltyRepository>(
      () => LoyaltyRepositoryImpl(getIt<LoyaltyDatasource>()),
    );
  }

  if (!getIt.isRegistered<GetLoyaltyDataUseCase>()) {
    getIt.registerLazySingleton<GetLoyaltyDataUseCase>(
      () => GetLoyaltyDataUseCase(getIt<LoyaltyRepository>()),
    );
  }

  if (!getIt.isRegistered<RedeemLoyaltyRewardUseCase>()) {
    getIt.registerLazySingleton<RedeemLoyaltyRewardUseCase>(
      () => RedeemLoyaltyRewardUseCase(getIt<LoyaltyRepository>()),
    );
  }

  if (!getIt.isRegistered<LoyaltyCubit>()) {
    getIt.registerFactory<LoyaltyCubit>(
      () => LoyaltyCubit(
        getData: getIt<GetLoyaltyDataUseCase>(),
        redeemReward: getIt<RedeemLoyaltyRewardUseCase>(),
      ),
    );
  }
}
