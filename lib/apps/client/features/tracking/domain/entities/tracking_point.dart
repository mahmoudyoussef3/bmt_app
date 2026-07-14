/// A single GPS fix reported by the captain's device.
class TrackingPoint {
  const TrackingPoint({
    required this.latitude,
    required this.longitude,
    this.recordedAt,
    this.heading,
    this.speed,
    this.accuracy,
  });

  final double latitude;
  final double longitude;
  final DateTime? recordedAt;

  /// Degrees clockwise from north; negative means the device had no heading.
  final double? heading;

  /// Ground speed in m/s, as reported by the device (Geolocator convention).
  final double? speed;

  /// Horizontal accuracy radius, in meters.
  final double? accuracy;

  /// Speed in km/h, or null when the device reported no usable speed.
  double? get speedKmh => speed == null || speed! < 0 ? null : speed! * 3.6;
}
