import '../../domain/entities/referral_rewards.dart';
import '../../domain/repositories/referral_rewards_repository.dart';
import '../datasources/supabase_referral_rewards_datasource.dart';

class ReferralRewardsRepositoryImpl implements ReferralRewardsRepository {
  const ReferralRewardsRepositoryImpl(this._datasource);

  final SupabaseReferralRewardsDatasource _datasource;

  @override
  Future<ReferralRewardsData> getReferralRewardsData() {
    return _datasource.getReferralRewardsData();
  }

  @override
  Future<int> redeemWalletBalance() {
    return _datasource.redeemWalletBalance();
  }
}
