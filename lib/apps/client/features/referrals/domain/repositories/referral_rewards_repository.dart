import '../entities/referral_rewards.dart';

abstract class ReferralRewardsRepository {
  Future<ReferralRewardsData> getReferralRewardsData();
}
