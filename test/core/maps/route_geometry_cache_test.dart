import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:bmt_app/core/maps/route_geometry_cache.dart';

RoadRoute _route(double marker) => RoadRoute(
      points: [LatLng(marker, marker), LatLng(marker + 1, marker + 1)],
      distanceMeters: marker * 1000,
      durationSeconds: marker * 60,
    );

void main() {
  group('signatureFor', () {
    test('is stable and order-sensitive', () {
      final a = [const LatLng(30.04441, 31.23571), const LatLng(31, 32)];
      final b = [const LatLng(31, 32), const LatLng(30.04441, 31.23571)];

      expect(
        RouteGeometryCache.signatureFor(a),
        RouteGeometryCache.signatureFor(a),
      );
      expect(
        RouteGeometryCache.signatureFor(a),
        isNot(RouteGeometryCache.signatureFor(b)),
      );
    });
  });

  group('RouteGeometryCache', () {
    test('round-trips stored routes', () {
      final cache = RouteGeometryCache();
      cache.put('key', _route(1));

      expect(cache.get('key')!.distanceMeters, 1000);
      expect(cache.get('missing'), isNull);
    });

    test('evicts the least recently used entry beyond capacity', () {
      final cache = RouteGeometryCache(capacity: 2);
      cache.put('first', _route(1));
      cache.put('second', _route(2));

      // Touch 'first' so 'second' becomes the eviction candidate.
      cache.get('first');
      cache.put('third', _route(3));

      expect(cache.length, 2);
      expect(cache.get('first'), isNotNull);
      expect(cache.get('second'), isNull);
      expect(cache.get('third'), isNotNull);
    });
  });
}
