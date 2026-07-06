import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/core/geo/polyline_codec.dart';

void main() {
  group('PolylineCodec.decode', () {
    test('decodes the reference encoded polyline', () {
      // Canonical example from the encoded-polyline format specification.
      final points = PolylineCodec.decode('_p~iF~ps|U_ulLnnqC_mqNvxq`@');

      expect(points, hasLength(3));
      expect(points[0].lat, closeTo(38.5, 1e-9));
      expect(points[0].lng, closeTo(-120.2, 1e-9));
      expect(points[1].lat, closeTo(40.7, 1e-9));
      expect(points[1].lng, closeTo(-120.95, 1e-9));
      expect(points[2].lat, closeTo(43.252, 1e-9));
      expect(points[2].lng, closeTo(-126.453, 1e-9));
    });

    test('returns empty list for empty input', () {
      expect(PolylineCodec.decode(''), isEmpty);
    });

    test('returns empty list for truncated input instead of throwing', () {
      // A lone latitude delta with no longitude runs past the end.
      expect(PolylineCodec.decode('_p~iF'), isEmpty);
    });

    test('supports precision 6 geometry', () {
      final five = PolylineCodec.decode('_p~iF~ps|U');
      final six = PolylineCodec.decode('_p~iF~ps|U', precision: 6);

      expect(six.single.lat, closeTo(five.single.lat / 10, 1e-9));
      expect(six.single.lng, closeTo(five.single.lng / 10, 1e-9));
    });
  });
}
