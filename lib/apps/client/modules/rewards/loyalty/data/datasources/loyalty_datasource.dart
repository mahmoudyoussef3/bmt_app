import '../../domain/entities/loyalty_data.dart';

abstract class LoyaltyDatasource {
  Future<LoyaltyData> getLoyaltyData();
  Future<void> redeemReward({
    required String rewardId,
    required String rewardTitle,
    required int pointsCost,
  });
}
