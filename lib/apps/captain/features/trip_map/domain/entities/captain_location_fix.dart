/// One GPS fix from the captain's own device, as the live-map source.
///
/// On the captain's map the vehicle *is* the captain — there is no second
/// device to track — so this comes straight from the phone's positioning
/// stream, not from `trip_live_locations`. It is display-only: the existing
/// 30-second publisher (`TripLocationAutoShare`) remains the sole writer that
/// feeds the client's map, so the captain map adds no database traffic.
///
/// Follows the Geolocator convention a negative [heading]/[speed] means "the
/// sensor had no value", so those are normalised to null here.
class CaptainLocationFix {
  const CaptainLocationFix({
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
    this.heading,
    this.speed,
    this.accuracy,
  });

  final double latitude;
  final double longitude;

  /// Device timestamp of the fix; staleness is measured against it.
  final DateTime recordedAt;

  /// Degrees clockwise from north, or null when the device reported none.
  final double? heading;

  /// Ground speed in m/s, or null when the device reported none.
  final double? speed;

  /// Horizontal accuracy radius in meters.
  final double? accuracy;

  /// Speed in km/h, or null when there is no usable reading.
  double? get speedKmh => speed == null || speed! < 0 ? null : speed! * 3.6;
}
