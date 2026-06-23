/// One row of the top-referrers leaderboard.
class ReferralLeaderboardItem {
  const ReferralLeaderboardItem({
    required this.rank,
    required this.referrerId,
    required this.name,
    required this.phone,
    required this.code,
    required this.totalReferrals,
    required this.completedReferrals,
    required this.pendingReferrals,
    required this.rewardsEarned,
    this.lastReferralAt,
  });

  final int rank;
  final String referrerId;
  final String name;
  final String phone;
  final String code;
  final int totalReferrals;
  final int completedReferrals;
  final int pendingReferrals;
  final double rewardsEarned;
  final DateTime? lastReferralAt;
}
