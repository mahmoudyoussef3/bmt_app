import '../entities/loyalty_data.dart';
import '../repositories/loyalty_repository.dart';

class RedeemLoyaltyRewardUseCase {
  const RedeemLoyaltyRewardUseCase(this._repository);

  final LoyaltyRepository _repository;

  Future<void> call(RedeemableReward reward) => _repository.redeemReward(
    rewardId: reward.id,
    rewardTitle: reward.title,
    pointsCost: reward.pointsCost,
  );
}
