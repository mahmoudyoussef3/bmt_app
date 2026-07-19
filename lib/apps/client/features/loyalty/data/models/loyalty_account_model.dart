/// A `loyalty_accounts` row.
///
/// Absent for riders who have never earned points, which reads as a zero
/// balance rather than an error.
class LoyaltyAccountModel {
  const LoyaltyAccountModel({required this.points});

  factory LoyaltyAccountModel.fromJson(Map<String, dynamic>? json) =>
      LoyaltyAccountModel(points: json?['points'] as int? ?? 0);

  final int points;
}
