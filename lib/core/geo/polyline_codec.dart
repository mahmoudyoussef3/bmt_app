import 'geo_models.dart';

/// Decoder for Google's encoded-polyline format, which ORS uses for the
/// `geometry` field of a directions response (precision 5, 2D).
class PolylineCodec {
  const PolylineCodec._();

  /// Decodes [encoded] into ordered coordinates. Returns an empty list for
  /// blank or malformed input instead of throwing: road geometry is a visual
  /// enhancement, so callers fall back to straight lines on bad data.
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
        index = deltaLat.$2;
        final deltaLng = _nextDelta(encoded, index);
        index = deltaLng.$2;
        lat += deltaLat.$1;
        lng += deltaLng.$1;
        points.add(GeoPoint(lat / factor, lng / factor));
      }
    } on RangeError {
      return const [];
    }
    return points;
  }

  /// Reads one varint-encoded, zigzag-signed delta starting at [start].
  /// Returns (delta, nextIndex).
  static (int, int) _nextDelta(String encoded, int start) {
    var index = start;
    var result = 0;
    var shift = 0;
    int byte;
    do {
      byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);
    final delta = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    return (delta, index);
  }

  static double _pow10(int exponent) {
    var value = 1.0;
    for (var i = 0; i < exponent; i++) {
      value *= 10;
    }
    return value;
  }
}
