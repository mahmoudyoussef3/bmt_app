import '../entities/referral_rewards.dart';
import '../repositories/referral_rewards_repository.dart';

class GetReferralRewardsDataUseCase {
  const GetReferralRewardsDataUseCase(this._repository);

  final ReferralRewardsRepository _repository;

  Future<ReferralRewardsData> call() {
    return _repository.getReferralRewardsData();
  }
}
