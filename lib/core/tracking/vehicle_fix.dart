/// A single raw GPS fix reported by a vehicle (captain device).
///
/// Follows Geolocator conventions: a negative [headingDegrees] or
/// [speedMetersPerSecond] means the sensor could not provide the value.
class VehicleFix {
  const VehicleFix({
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
    this.headingDegrees,
    this.speedMetersPerSecond,
    this.accuracyMeters,
  });

  final double latitude;
  final double longitude;

  /// Device timestamp of the fix (used for ordering and "sent X ago" labels).
  final DateTime recordedAt;

  /// Course over ground in degrees clockwise from north, if reported.
  final double? headingDegrees;

  /// Ground speed in m/s, if reported.
  final double? speedMetersPerSecond;

  /// Horizontal accuracy radius in meters (68% confidence), if reported.
  final double? accuracyMeters;

  bool get hasValidHeading =>
      headingDegrees != null &&
      headingDegrees!.isFinite &&
      headingDegrees! >= 0;

  bool get hasValidSpeed =>
      speedMetersPerSecond != null &&
      speedMetersPerSecond!.isFinite &&
      speedMetersPerSecond! >= 0;

  bool get hasValidAccuracy =>
      accuracyMeters != null && accuracyMeters!.isFinite && accuracyMeters! > 0;

  @override
  String toString() =>
      'VehicleFix($latitude, $longitude, at: $recordedAt, '
      'heading: $headingDegrees, speed: $speedMetersPerSecond m/s, '
      'accuracy: $accuracyMeters m)';
}
