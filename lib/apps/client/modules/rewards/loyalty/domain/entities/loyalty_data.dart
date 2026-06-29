class LoyaltyTier {
  const LoyaltyTier({
    required this.name,
    required this.pointsRequired,
    required this.perks,
    required this.gradientColors,
    required this.iconKey,
  });

  final String name;
  final String pointsRequired;
  final List<String> perks;
  final List<int> gradientColors;
  final String iconKey;
}

class PointsTransaction {
  const PointsTransaction({
    required this.title,
    required this.date,
    required this.points,
    required this.isEarned,
    this.expirationDate,
  });

  final String title;
  final String date;
  final int points;
  final bool isEarned;
  final String? expirationDate;
}

class RedeemableReward {
  const RedeemableReward({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsCost,
    required this.valueLabel,
    required this.category,
    required this.couponCode,
  });

  final String id;
  final String title;
  final String description;
  final int pointsCost;
  final String valueLabel;
  final String category;
  final String couponCode;
}

class LoyaltyData {
  const LoyaltyData({
    required this.currentPoints,
    required this.currentTierName,
    required this.tiers,
    required this.transactions,
    required this.rewards,
  });

  final int currentPoints;
  final String currentTierName;
  final List<LoyaltyTier> tiers;
  final List<PointsTransaction> transactions;
  final List<RedeemableReward> rewards;

  LoyaltyData copyWith({int? currentPoints, String? currentTierName}) {
    return LoyaltyData(
      currentPoints: currentPoints ?? this.currentPoints,
      currentTierName: currentTierName ?? this.currentTierName,
      tiers: tiers,
      transactions: transactions,
      rewards: rewards,
    );
  }
}
