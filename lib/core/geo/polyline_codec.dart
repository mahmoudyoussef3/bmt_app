import 'geo_models.dart';

/// Decoder for Google's encoded-polyline format, which ORS uses for the
/// `geometry` field of a directions response (precision 5, 2D).
///
/// Deliberately written with arithmetic (`+`, `*`, `~/`, `isOdd`) instead of
/// the usual bitwise operators: on the web, Dart's `int` is a JS double and
/// `~`, `<<`, `>>`, `&` are evaluated as *unsigned 32-bit*. `~n` there returns
/// `4294967295 - n` instead of `-n - 1`, so every southward/westward delta
/// decoded into a ~4.3e9 jump, the accumulator ran to ~1e12, and the map threw
/// `LatLngBounds`' "north latitude can't be bigger than 90". The arithmetic
/// form is exact on every platform.
class PolylineCodec {
  const PolylineCodec._();

  /// Largest number of 5-bit groups a single varint may use before the input is
  /// considered malformed. World coordinates at precision 6 need 6 groups; the
  /// cap stops a corrupt string from accumulating an unbounded value.
  static const _maxGroups = 7;

  /// Decodes [encoded] into ordered coordinates. Returns an empty list for
  /// blank, malformed or out-of-range input instead of throwing: road geometry
  /// is a visual enhancement, so callers fall back to straight lines on bad
  /// data rather than crashing the map.
  static List<GeoPoint> decode(String encoded, {int precision = 5}) {
    if (encoded.isEmpty) return const [];
    final factor = _pow10(precision);
    final points = <GeoPoint>[];
    var index = 0;
    var lat = 0;
    var lng = 0;

    try {
      while (index < encoded.length) {
        final deltaLat = _nextDelta(encoded, index);
        if (deltaLat == null) return const [];
        index = deltaLat.$2;
        final deltaLng = _nextDelta(encoded, index);
        if (deltaLng == null) return const [];
        index = deltaLng.$2;
        lat += deltaLat.$1;
        lng += deltaLng.$1;

        final point = GeoPoint(lat / factor, lng / factor);
        // One bad point means the accumulator has drifted, so everything after
        // it is wrong too — drop the whole geometry instead of drawing a line
        // that leaves the world.
        if (!_isOnEarth(point)) return const [];
        points.add(point);
      }
    } on RangeError {
      return const [];
    }
    return points;
  }

  static bool _isOnEarth(GeoPoint point) =>
      point.lat >= -90 &&
      point.lat <= 90 &&
      point.lng >= -180 &&
      point.lng <= 180;

  /// Reads one varint-encoded, zigzag-signed delta starting at [start].
  /// Returns (delta, nextIndex), or `null` when the varint is malformed.
  static (int, int)? _nextDelta(String encoded, int start) {
    var index = start;
    var result = 0;
    var multiplier = 1;
    var groups = 0;
    int byte;
    do {
      if (groups++ >= _maxGroups) return null;
      byte = encoded.codeUnitAt(index++) - 63;
      if (byte < 0) return null;
      result += (byte % 32) * multiplier;
      multiplier *= 32;
    } while (byte >= 0x20);

    // Zigzag: the low bit carries the sign, the rest is the magnitude.
    final magnitude = result ~/ 2;
    return (result.isOdd ? -magnitude - 1 : magnitude, index);
  }

  static double _pow10(int exponent) {
    var value = 1.0;
    for (var i = 0; i < exponent; i++) {
      value *= 10;
    }
    return value;
  }
}
