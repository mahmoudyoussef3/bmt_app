/// A membership level as configured by the operator in `loyalty_tiers`.
///
/// [gradientColors] and [iconKey] are backend-owned *branding* rather than UI
/// decisions — the operator picks a tier's look in Supabase — which is why they
/// travel with the entity. Presentation resolves them to concrete colors and
/// icons rather than the domain knowing about either.
class LoyaltyTier {
  const LoyaltyTier({
    required this.name,
    required this.pointsRequiredLabel,
    required this.perks,
    required this.gradientColors,
    required this.iconKey,
  });

  /// Canonical name, matched against [LoyaltyTierLadder.tierNameFor].
  final String name;

  /// Pre-formatted entry requirement, e.g. `"1000 pts"`.
  final String pointsRequiredLabel;

  final List<String> perks;

  /// ARGB gradient stops. Always holds at least two entries.
  final List<int> gradientColors;

  final String iconKey;
}
