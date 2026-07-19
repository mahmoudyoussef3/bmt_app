/// The points thresholds that define membership progression.
///
/// Single source of truth: the data layer derives the rider's current tier from
/// it, and presentation renders progress toward the top tier from it. Keeping
/// both on this ladder is what stops the screen and the datasource from
/// disagreeing about what "Platinum" costs.
abstract final class LoyaltyTierLadder {
  const LoyaltyTierLadder._();

  static const int bronze = 0;
  static const int silver = 1000;
  static const int gold = 2000;
  static const int platinum = 3000;

  /// Canonical tier name for [points], matched against `loyalty_tiers.name`.
  static String tierNameFor(int points) {
    if (points >= platinum) return 'Platinum';
    if (points >= gold) return 'Gold';
    if (points >= silver) return 'Silver';
    return 'Bronze';
  }

  /// Progress toward [platinum] as a 0..1 fraction.
  static double progressToTop(int points) =>
      (points / platinum).clamp(0.0, 1.0);

  /// Points still needed to reach [platinum]; zero once there.
  static int pointsToTop(int points) =>
      points >= platinum ? 0 : platinum - points;
}
