import '../../domain/entities/referral_rewards.dart';

sealed class ReferralRewardsState {
  const ReferralRewardsState();
}

class ReferralRewardsLoading extends ReferralRewardsState {
  const ReferralRewardsLoading();
}

class ReferralRewardsLoaded extends ReferralRewardsState {
  const ReferralRewardsLoaded(this.data);

  final ReferralRewardsData data;
}

class ReferralRewardsError extends ReferralRewardsState {
  const ReferralRewardsError(this.message);

  final String message;
}
