/// Lifecycle status of a referral, matching `referrals.status` in the schema.
enum ReferralStatus {
  pendingRegistration,
  registered,
  firstOrderCompleted,
  rewardGranted,
  unknown;

  static ReferralStatus fromDb(String? raw) => switch (raw) {
    'pending_registration' => ReferralStatus.pendingRegistration,
    'registered' => ReferralStatus.registered,
    'first_order_completed' => ReferralStatus.firstOrderCompleted,
    'reward_granted' || 'completed' => ReferralStatus.rewardGranted,
    _ => ReferralStatus.unknown,
  };

  /// A referral is "successful" once the referred user reaches the first order.
  bool get isSuccessful =>
      this == ReferralStatus.firstOrderCompleted ||
      this == ReferralStatus.rewardGranted;

  bool get isPending =>
      this == ReferralStatus.pendingRegistration ||
      this == ReferralStatus.registered;
}

/// A full referral record from the `referrals` table.
class ReferralRecord {
  const ReferralRecord({
    required this.id,
    required this.code,
    required this.referrerId,
    required this.referrerName,
    required this.referredId,
    required this.referredName,
    required this.status,
    required this.rewardType,
    required this.rewardValue,
    required this.rewardStatus,
    required this.createdAt,
    this.firstOrderId,
    this.firstOrderAt,
    this.rewardedAt,
  });

  final String id;
  final String code;
  final String referrerId;
  final String referrerName;
  final String referredId;
  final String referredName;
  final ReferralStatus status;
  final String rewardType;
  final double rewardValue;
  final String rewardStatus;
  final String? firstOrderId;
  final DateTime createdAt;
  final DateTime? firstOrderAt;
  final DateTime? rewardedAt;
}
