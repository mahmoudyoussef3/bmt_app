/// Tunables for the live vehicle tracking engine.
///
/// Defaults are calibrated for intercity bus operations where the captain
/// device reports fixes at irregular intervals (seconds to minutes apart).
class TrackingConfig {
  const TrackingConfig({
    this.maxAccuracyMeters = defaultMaxAccuracyMeters,
    this.maxPlausibleSpeedMps = 55,
    this.snapDistanceMeters = 1000,
    this.minAnimation = const Duration(milliseconds: 300),
    this.maxAnimation = const Duration(seconds: 6),
    this.movingSpeedThresholdKmh = 3,
    this.minBearingDistanceMeters = 3,
    this.speedSmoothing = 0.35,
    this.staleAfter = const Duration(minutes: 2),
  });

  /// Fixes with a worse (larger) reported accuracy are rejected as noise.
  final double maxAccuracyMeters;

  /// Named so the producer side can share it: a fix the marker engine would
  /// reject is not worth a database write. See `LiveTrackingConfig`.
  static const double defaultMaxAccuracyMeters = 100;

  /// Fixes implying a faster ground speed than this (m/s) are rejected as
  /// GPS glitches. 55 m/s ≈ 200 km/h.
  final double maxPlausibleSpeedMps;

  /// Jumps longer than this teleport the marker instead of animating, so a
  /// vehicle that went dark for a while does not crawl across the map.
  final double snapDistanceMeters;

  /// Bounds for the marker animation window. The engine animates over the
  /// observed inter-fix interval, clamped into [minAnimation, maxAnimation],
  /// so steady streams glide continuously and sparse sends stay snappy.
  final Duration minAnimation;
  final Duration maxAnimation;

  /// Below this smoothed speed the vehicle is considered stationary: the
  /// marker keeps its last heading and device headings are distrusted.
  final double movingSpeedThresholdKmh;

  /// Minimum displacement between fixes before a path bearing is derived;
  /// closer fixes are GPS jitter and would produce random headings.
  final double minBearingDistanceMeters;

  /// Exponential smoothing factor for speed (0 exclusive..1]; higher reacts
  /// faster, lower is smoother.
  final double speedSmoothing;

  /// Without a new fix for this long the sample is flagged stale (measured
  /// against receipt time, so device clock skew cannot fake freshness).
  final Duration staleAfter;
}
