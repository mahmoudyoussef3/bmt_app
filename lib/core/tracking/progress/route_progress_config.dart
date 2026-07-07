/// Tunables for the route progress & ETA engine.
///
/// Defaults are calibrated for intercity bus routes where stops are hundreds
/// of meters to kilometers apart and GPS fixes arrive irregularly.
class RouteProgressConfig {
  const RouteProgressConfig({
    this.arrivalRadiusMeters = 150,
    this.departRadiusMeters = 250,
    this.passedStopSlackMeters = 300,
    this.offRouteMeters = 500,
    this.backtrackToleranceMeters = 200,
    this.approachIndirectness = 1.3,
    this.fallbackSpeedKmh = 35,
    this.minEffectiveSpeedKmh = 12,
    this.maxEffectiveSpeedKmh = 90,
    this.liveSpeedWeight = 0.7,
    this.minMovingSpeedKmh = 5,
    this.dwellPerStop = const Duration(seconds: 45),
    this.staleAfter = const Duration(minutes: 2),
  });

  /// Within this distance of a stop the vehicle counts as arrived there.
  final double arrivalRadiusMeters;

  /// An arrived vehicle must move this far from the stop to count as
  /// departed — larger than the arrival radius so GPS jitter at a station
  /// cannot flap arrived/departed.
  final double departRadiusMeters;

  /// A stop is marked passed (departed without a detected dwell) once the
  /// along-route position is this far beyond it. Covers stops the bus rolls
  /// through and arrival fixes lost to sparse reporting.
  final double passedStopSlackMeters;

  /// Cross-track distance beyond which the vehicle is flagged off-route and
  /// progress stops advancing.
  final double offRouteMeters;

  /// Along-route regression tolerated when matching a fix to the polyline;
  /// protects loop-shaped routes from snapping the bus backwards.
  final double backtrackToleranceMeters;

  /// Straight-line → road distance multiplier used before the trip starts,
  /// when the driver's actual path to the pickup point is unknown.
  final double approachIndirectness;

  /// Speed assumed when neither live GPS, trip history, nor a schedule pace
  /// is available.
  final double fallbackSpeedKmh;

  /// Effective speed used for ETAs is clamped into this band so a crawling
  /// or speeding outlier cannot produce absurd estimates.
  final double minEffectiveSpeedKmh;
  final double maxEffectiveSpeedKmh;

  /// Blend weight of the live speed against the schedule/history pace.
  final double liveSpeedWeight;

  /// Below this speed the vehicle is treated as dwelling; ETAs then lean on
  /// the trip average or schedule pace instead of the live reading.
  final double minMovingSpeedKmh;

  /// Boarding/alighting time budgeted per intermediate stop ahead.
  final Duration dwellPerStop;

  /// Without a fix for this long (receipt time), ETAs degrade to the
  /// published schedule.
  final Duration staleAfter;
}
