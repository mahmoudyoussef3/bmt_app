import 'loyalty_account_model.dart';
import 'loyalty_reward_model.dart';
import 'loyalty_tier_model.dart';
import 'points_transaction_model.dart';

/// One read of everything the loyalty hub needs.
///
/// The datasource returns this rather than four separate calls so the repo maps
/// a single consistent snapshot — a balance and the ledger that explains it can
/// never come from two different moments.
class LoyaltySnapshotModel {
  const LoyaltySnapshotModel({
    required this.account,
    required this.transactions,
    required this.tiers,
    required this.rewards,
  });

  final LoyaltyAccountModel account;
  final List<PointsTransactionModel> transactions;
  final List<LoyaltyTierModel> tiers;
  final List<LoyaltyRewardModel> rewards;
}
