/// A `loyalty_transactions` row.
class PointsTransactionModel {
  const PointsTransactionModel({
    required this.title,
    required this.createdAt,
    required this.points,
    required this.isEarned,
  });

  factory PointsTransactionModel.fromJson(Map<String, dynamic> json) =>
      PointsTransactionModel(
        title: json['title']?.toString() ?? '',
        createdAt: json['created_at']?.toString(),
        points: json['points'] as int? ?? 0,
        isEarned: json['is_earned'] as bool? ?? true,
      );

  final String title;

  /// Raw ISO-8601 timestamp; the mapper reduces it to a calendar day.
  final String? createdAt;

  /// Signed as stored — redemptions are written negative.
  final int points;

  final bool isEarned;
}
