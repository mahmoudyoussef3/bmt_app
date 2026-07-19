/// A `loyalty_tiers` row.
class LoyaltyTierModel {
  const LoyaltyTierModel({
    required this.name,
    required this.pointsRequired,
    required this.iconKey,
    required this.gradientColors,
    required this.perks,
  });

  factory LoyaltyTierModel.fromJson(Map<String, dynamic> json) {
    return LoyaltyTierModel(
      name: json['name']?.toString() ?? 'Tier',
      pointsRequired: json['points_required']?.toString() ?? '0 pts',
      iconKey: json['icon_key']?.toString() ?? 'stars',
      gradientColors: _gradientStops(json['gradient_colors']),
      perks:
          (json['perks'] as List<dynamic>?)
              ?.map((perk) => perk.toString())
              .toList() ??
          const <String>[],
    );
  }

  final String name;
  final String pointsRequired;
  final String iconKey;
  final List<int> gradientColors;
  final List<String> perks;

  /// Neutral slate, used whenever the operator's branding is missing or
  /// unusable.
  static const List<int> _fallback = <int>[0xFFB0BEC5, 0xFF607D8B];

  /// Gradient stops arrive as ARGB strings. A `LinearGradient` needs at least
  /// two, so anything shorter — including a present-but-empty column — falls
  /// back rather than reaching the painter and throwing.
  static List<int> _gradientStops(dynamic raw) {
    final stops = (raw as List<dynamic>?)
        ?.map((stop) => int.tryParse(stop.toString()))
        .whereType<int>()
        .toList();
    return (stops == null || stops.length < 2) ? _fallback : stops;
  }
}
