import '../entities/loyalty_data.dart';

abstract class LoyaltyRepository {
  Future<LoyaltyData> getLoyaltyData();
  Future<void> redeemReward({
    required String rewardId,
    required String rewardTitle,
    required int pointsCost,
  });
}
