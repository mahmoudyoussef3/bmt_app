import '../../domain/entities/loyalty_data.dart';
import '../../domain/entities/loyalty_tier.dart';
import '../../domain/entities/loyalty_tier_ladder.dart';
import '../../domain/entities/points_transaction.dart';
import '../../domain/entities/redeemable_reward.dart';
import '../models/loyalty_reward_model.dart';
import '../models/loyalty_snapshot_model.dart';
import '../models/loyalty_tier_model.dart';
import '../models/points_transaction_model.dart';

extension LoyaltyTierMapper on LoyaltyTierModel {
  LoyaltyTier toEntity() => LoyaltyTier(
    name: name,
    pointsRequiredLabel: pointsRequired,
    perks: perks,
    gradientColors: gradientColors,
    iconKey: iconKey,
  );
}

extension PointsTransactionMapper on PointsTransactionModel {
  /// Normalizes the ledger's signed amount to a magnitude — [isEarned] already
  /// carries the direction, and rendering both produced `--500 pts`.
  PointsTransaction toEntity() => PointsTransaction(
    title: title,
    date: _calendarDay(createdAt),
    points: points.abs(),
    isEarned: isEarned,
  );
}

extension LoyaltyRewardMapper on LoyaltyRewardModel {
  RedeemableReward toEntity() => RedeemableReward(
    id: id,
    title: title,
    description: description,
    pointsCost: pointsCost,
    valueLabel: valueLabel,
    category: category,
    couponCode: couponCode,
  );
}

extension LoyaltySnapshotMapper on LoyaltySnapshotModel {
  LoyaltyData toEntity() => LoyaltyData(
    currentPoints: account.points,
    currentTierName: LoyaltyTierLadder.tierNameFor(account.points),
    tiers: tiers.map((tier) => tier.toEntity()).toList(),
    transactions: transactions.map((tx) => tx.toEntity()).toList(),
    rewards: rewards.map((reward) => reward.toEntity()).toList(),
  );
}

/// Reduces an ISO-8601 timestamp to its calendar day. Returns an empty string
/// for a missing or malformed value so presentation can omit the date line
/// instead of printing a hardcoded English `"Unknown"`.
String _calendarDay(String? timestamp) {
  if (timestamp == null || timestamp.isEmpty) return '';
  final separator = timestamp.indexOf('T');
  return separator == -1 ? timestamp : timestamp.substring(0, separator);
}
