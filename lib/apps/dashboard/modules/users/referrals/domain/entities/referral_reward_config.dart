/// Reward engine configuration (the single `referral_rewards` row).
class ReferralRewardConfig {
  const ReferralRewardConfig({
    required this.enabled,
    required this.rewardType,
    required this.rewardValue,
    required this.referredValue,
    required this.currency,
    this.couponCode,
    this.updatedAt,
  });

  /// Master on/off switch for the whole referral program.
  final bool enabled;

  /// One of: `points`, `wallet`, `coupon`, `loyalty`.
  final String rewardType;

  /// Reward granted to the referrer.
  final double rewardValue;

  /// Welcome reward granted to the referred customer.
  final double referredValue;

  final String currency;
  final String? couponCode;
  final DateTime? updatedAt;

  static const rewardTypes = <String>['points', 'wallet', 'coupon', 'loyalty'];

  ReferralRewardConfig copyWith({
    bool? enabled,
    String? rewardType,
    double? rewardValue,
    double? referredValue,
    String? currency,
    String? couponCode,
  }) {
    return ReferralRewardConfig(
      enabled: enabled ?? this.enabled,
      rewardType: rewardType ?? this.rewardType,
      rewardValue: rewardValue ?? this.rewardValue,
      referredValue: referredValue ?? this.referredValue,
      currency: currency ?? this.currency,
      couponCode: couponCode ?? this.couponCode,
      updatedAt: updatedAt,
    );
  }
}
