/// An interpolated, render-ready snapshot of a tracked vehicle.
///
/// Produced by `VehicleTrackingEngine.sample`; consumers draw the marker at
/// ([latitude], [longitude]) rotated to [headingDegrees] with an accuracy
/// circle of [accuracyMeters].
class VehicleSample {
  const VehicleSample({
    required this.latitude,
    required this.longitude,
    required this.headingDegrees,
    required this.speedKmh,
    required this.fixRecordedAt,
    required this.isInterpolating,
    required this.isMoving,
    required this.isStale,
    this.accuracyMeters,
  });

  final double latitude;
  final double longitude;

  /// Smoothed heading in degrees clockwise from north, [0, 360).
  final double headingDegrees;

  /// Smoothed ground speed in km/h (estimated when the device omits it).
  final double speedKmh;

  /// Horizontal accuracy radius in meters, when known.
  final double? accuracyMeters;

  /// Device timestamp of the fix currently being rendered/approached.
  final DateTime fixRecordedAt;

  /// True while the marker is animating between two fixes.
  final bool isInterpolating;

  /// True when the smoothed speed indicates the vehicle is in motion.
  final bool isMoving;

  /// True when no fix has been received for longer than the stale window.
  final bool isStale;

  @override
  String toString() =>
      'VehicleSample($latitude, $longitude, heading: $headingDegrees°, '
      '$speedKmh km/h, stale: $isStale)';
}
