import '../entities/loyalty_data.dart';
import '../entities/redeemable_reward.dart';

abstract class LoyaltyRepository {
  Future<LoyaltyData> getLoyaltyData();

  /// Debits [reward]'s cost and writes the matching ledger row.
  ///
  /// Throws when the rider can no longer afford the reward — including when a
  /// concurrent redemption spent the balance first.
  Future<void> redeemReward(RedeemableReward reward);
}
