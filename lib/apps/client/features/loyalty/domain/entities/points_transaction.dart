/// One row of the rider's points ledger.
class PointsTransaction {
  const PointsTransaction({
    required this.title,
    required this.date,
    required this.points,
    required this.isEarned,
  });

  /// Operator-supplied description. May be empty when the row predates
  /// titled transactions — presentation substitutes a localized fallback.
  final String title;

  /// Calendar day (`yyyy-MM-dd`), or empty when the row carries no timestamp.
  final String date;

  /// Always a magnitude. The ledger stores redemptions as negative numbers;
  /// the sign lives in [isEarned] so presentation never renders `--500`.
  final int points;

  final bool isEarned;
}
