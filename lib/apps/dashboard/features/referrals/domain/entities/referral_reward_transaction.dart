/// One immutable row of the `referral_reward_transactions` ledger.
class ReferralRewardTransaction {
  const ReferralRewardTransaction({
    required this.id,
    required this.referralId,
    required this.userId,
    required this.userName,
    required this.role,
    required this.rewardType,
    required this.rewardValue,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String referralId;
  final String userId;
  final String userName;

  /// `referrer` or `referred`.
  final String role;
  final String rewardType;
  final double rewardValue;
  final String status;
  final DateTime createdAt;
}
