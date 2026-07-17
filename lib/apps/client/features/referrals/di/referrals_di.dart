// GENERATED_PLACEHOLDER_HEADER
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bmt_app/apps/client/features/referrals/data/datasources/supabase_referral_rewards_datasource.dart';
import 'package:bmt_app/apps/client/features/referrals/data/repositories/referral_rewards_repository_impl.dart';
import 'package:bmt_app/apps/client/features/referrals/domain/repositories/referral_rewards_repository.dart';
import 'package:bmt_app/apps/client/features/referrals/domain/usecases/get_referral_rewards_data_usecase.dart';
import 'package:bmt_app/apps/client/features/referrals/domain/usecases/update_referral_rewards_usecase.dart';
import 'package:bmt_app/apps/client/features/referrals/presentation/cubit/referral_rewards_cubit.dart';

/// Registers the referrals feature's data sources, repositories, use
/// cases and cubits. Idempotent: safe to call more than once.
void registerReferralRewardsDependencies(GetIt getIt) {
  if (!getIt.isRegistered<SupabaseReferralRewardsDatasource>()) {
    getIt.registerLazySingleton<SupabaseReferralRewardsDatasource>(
      () => SupabaseReferralRewardsDatasource(Supabase.instance.client),
    );
  }

  if (!getIt.isRegistered<ReferralRewardsRepository>()) {
    getIt.registerLazySingleton<ReferralRewardsRepository>(
      () => ReferralRewardsRepositoryImpl(
        getIt<SupabaseReferralRewardsDatasource>(),
      ),
    );
  }

  if (!getIt.isRegistered<GetReferralRewardsDataUseCase>()) {
    getIt.registerLazySingleton<GetReferralRewardsDataUseCase>(
      () => GetReferralRewardsDataUseCase(
        getIt<ReferralRewardsRepository>(),
      ),
    );
  }

  if (!getIt.isRegistered<InviteContactUseCase>()) {
    getIt.registerLazySingleton<InviteContactUseCase>(
      () => const InviteContactUseCase(),
    );
  }

  if (!getIt.isRegistered<RedeemRewardsUseCase>()) {
    getIt.registerLazySingleton<RedeemRewardsUseCase>(
      () => RedeemRewardsUseCase(getIt<ReferralRewardsRepository>()),
    );
  }

  if (!getIt.isRegistered<RevealVoucherUseCase>()) {
    getIt.registerLazySingleton<RevealVoucherUseCase>(
      () => const RevealVoucherUseCase(),
    );
  }

  if (!getIt.isRegistered<ReferralRewardsCubit>()) {
    getIt.registerFactory<ReferralRewardsCubit>(
      () => ReferralRewardsCubit(
        getData: getIt<GetReferralRewardsDataUseCase>(),
        inviteContact: getIt<InviteContactUseCase>(),
        redeemRewards: getIt<RedeemRewardsUseCase>(),
        revealVoucher: getIt<RevealVoucherUseCase>(),
      ),
    );
  }
}
