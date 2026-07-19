/// A catalog reward the rider can exchange points for.
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

  /// Pre-formatted headline value, e.g. `"20% OFF"`.
  final String valueLabel;

  /// Operator-defined grouping (`Discount`, `FreeRide`, `Cashback`,
  /// `Package`). Presentation maps known values to a label, icon and color.
  final String category;

  final String couponCode;
}
