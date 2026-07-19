import '../../domain/entities/loyalty_tier.dart';

/// A neutral stand-in for when `loyalty_tiers` has no row for the rider's
/// earned tier — including when the operator hasn't provisioned the table at
/// all and the datasource degrades it to an empty list.
///
/// The balance is the most important thing on the dashboard, so it keeps its
/// hero card instead of disappearing along with the tier catalog.
LoyaltyTier fallbackTier(String name) => LoyaltyTier(
  name: name,
  pointsRequiredLabel: '',
  perks: const <String>[],
  gradientColors: const <int>[0xFFB0BEC5, 0xFF607D8B],
  iconKey: 'stars',
);
