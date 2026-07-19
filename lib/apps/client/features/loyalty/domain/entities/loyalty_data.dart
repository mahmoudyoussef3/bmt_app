import 'loyalty_tier.dart';
import 'points_transaction.dart';
import 'redeemable_reward.dart';

/// Everything the loyalty hub renders, fetched as one snapshot.
class LoyaltyData {
  const LoyaltyData({
    required this.currentPoints,
    required this.currentTierName,
    required this.tiers,
    required this.transactions,
    required this.rewards,
  });

  final int currentPoints;

  /// Derived from [currentPoints] via `LoyaltyTierLadder`, not read from the
  /// account row — the ladder is the authority on which tier a balance earns.
  final String currentTierName;

  final List<LoyaltyTier> tiers;
  final List<PointsTransaction> transactions;
  final List<RedeemableReward> rewards;

  /// The tier matching [currentTierName], or `null` when the operator has not
  /// provisioned `loyalty_tiers` (the datasource degrades a missing catalog
  /// table to an empty list) or has no row for the earned tier.
  ///
  /// Callers must handle `null`. Reaching for `firstWhere` here is what used to
  /// throw a `StateError` on exactly the degraded path the fetch was written to
  /// survive.
  LoyaltyTier? get activeTier {
    for (final tier in tiers) {
      if (tier.name == currentTierName) return tier;
    }
    return null;
  }

  /// Whether [reward] is within the rider's current balance.
  bool canAfford(RedeemableReward reward) => currentPoints >= reward.pointsCost;
}
