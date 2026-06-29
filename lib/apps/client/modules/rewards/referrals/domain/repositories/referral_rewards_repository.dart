import '../entities/referral_rewards.dart';

abstract class ReferralRewardsRepository {
  Future<ReferralRewardsData> getReferralRewardsData();

  /// Moves the current wallet balance into the user's redeemed total in
  /// Supabase and resets the balance to zero. Returns the amount redeemed.
  Future<int> redeemWalletBalance();
}
