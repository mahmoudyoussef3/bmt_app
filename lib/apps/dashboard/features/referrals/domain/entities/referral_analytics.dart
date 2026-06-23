/// Aggregated referral program metrics for the Overview tab.
class ReferralAnalytics {
  const ReferralAnalytics({
    required this.totalCodes,
    required this.totalReferrals,
    required this.pendingReferrals,
    required this.firstOrderCompleted,
    required this.rewardGranted,
    required this.conversionRate,
    required this.referrerRewards,
    required this.referredRewards,
    required this.totalRewards,
  });

  final int totalCodes;
  final int totalReferrals;
  final int pendingReferrals;
  final int firstOrderCompleted;
  final int rewardGranted;

  /// Percentage 0–100 (successful / total).
  final double conversionRate;

  final double referrerRewards;
  final double referredRewards;
  final double totalRewards;

  static const empty = ReferralAnalytics(
    totalCodes: 0,
    totalReferrals: 0,
    pendingReferrals: 0,
    firstOrderCompleted: 0,
    rewardGranted: 0,
    conversionRate: 0,
    referrerRewards: 0,
    referredRewards: 0,
    totalRewards: 0,
  );
}
