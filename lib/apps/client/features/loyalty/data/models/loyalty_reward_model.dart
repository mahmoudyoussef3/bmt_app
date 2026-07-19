/// A `loyalty_rewards` row.
class LoyaltyRewardModel {
  const LoyaltyRewardModel({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsCost,
    required this.valueLabel,
    required this.category,
    required this.couponCode,
  });

  factory LoyaltyRewardModel.fromJson(Map<String, dynamic> json) =>
      LoyaltyRewardModel(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        pointsCost: json['points_cost'] as int? ?? 0,
        valueLabel: json['value_label']?.toString() ?? '',
        category: json['category']?.toString() ?? 'Discount',
        couponCode: json['coupon_code']?.toString() ?? '',
      );

  final String id;
  final String title;
  final String description;
  final int pointsCost;
  final String valueLabel;
  final String category;
  final String couponCode;
}
