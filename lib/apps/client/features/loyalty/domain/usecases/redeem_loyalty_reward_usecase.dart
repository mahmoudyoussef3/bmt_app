import '../entities/loyalty_data.dart';

class RedeemLoyaltyRewardUseCase {
  const RedeemLoyaltyRewardUseCase();

  LoyaltyData call(LoyaltyData data, RedeemableReward reward) {
    final points = data.currentPoints - reward.pointsCost;
    final tier = points >= 3000
        ? 'Platinum'
        : points >= 2000
        ? 'Gold'
        : points >= 1000
        ? 'Silver'
        : 'Bronze';
    return data.copyWith(currentPoints: points, currentTierName: tier);
  }
}
