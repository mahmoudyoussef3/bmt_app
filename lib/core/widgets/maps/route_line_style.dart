/// Stroke weights for an EasyWay route line.
///
/// A route line is drawn as up to three stacked strokes: an outer glow, a
/// contrasting casing, then the colored core. The weights differ by what the
/// line is *for*.
class RouteLineStyle {
  const RouteLineStyle({
    required this.glowWidth,
    required this.casingWidth,
    required this.coreWidth,
  });

  final double glowWidth;
  final double casingWidth;
  final double coreWidth;

  /// Route Discovery / Route Details: the line *is* the content, so it carries
  /// the full glow-and-casing treatment.
  static const hero = RouteLineStyle(
    glowWidth: 15,
    casingWidth: 11,
    coreWidth: 6,
  );

  /// Live tracking: the line is context behind a moving vehicle. At hero
  /// weight it buries the stop markers and the vehicle puck under a fat band,
  /// so it is drawn about a third slimmer with no glow.
  static const navigation = RouteLineStyle(
    glowWidth: 0,
    casingWidth: 7.5,
    coreWidth: 4.5,
  );

  /// The part of the route already covered: a bare hairline, no casing, no
  /// glow — done work should recede, not compete with the road ahead.
  static const trail = RouteLineStyle(
    glowWidth: 0,
    casingWidth: 0,
    coreWidth: 3.5,
  );
}
