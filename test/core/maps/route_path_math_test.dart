import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:bmt_app/core/maps/route_path_math.dart';

void main() {
  group('cumulativeDistances', () {
    test('starts at zero and grows monotonically', () {
      final points = [
        const LatLng(30.0444, 31.2357),
        const LatLng(30.0561, 31.2394),
        const LatLng(30.0721, 31.2465),
      ];
      final cumulative = RoutePathMath.cumulativeDistances(points);

      expect(cumulative, hasLength(3));
      expect(cumulative.first, 0);
      expect(cumulative[1], greaterThan(0));
      expect(cumulative[2], greaterThan(cumulative[1]));
    });

    test('is empty for no points', () {
      expect(RoutePathMath.cumulativeDistances(const []), isEmpty);
    });
  });

  group('pathPrefix', () {
    final points = [
      const LatLng(0, 0),
      const LatLng(0, 1),
      const LatLng(0, 2),
    ];
    final cumulative = RoutePathMath.cumulativeDistances(points);

    test('returns nothing at fraction 0 and everything at fraction 1', () {
      expect(RoutePathMath.pathPrefix(points, cumulative, 0), isEmpty);
      expect(RoutePathMath.pathPrefix(points, cumulative, 1), points);
    });

    test('interpolates a smooth tip at half the route', () {
      final prefix = RoutePathMath.pathPrefix(points, cumulative, 0.5);

      // Half of the equator-aligned 2-degree path ends at ~1 degree east.
      expect(prefix.first, points.first);
      expect(prefix.last.latitude, closeTo(0, 1e-6));
      expect(prefix.last.longitude, closeTo(1, 1e-2));
    });
  });

  group('splitAtFraction', () {
    final points = [
      const LatLng(0, 0),
      const LatLng(0, 1),
      const LatLng(0, 2),
    ];
    final cumulative = RoutePathMath.cumulativeDistances(points);

    test('all remaining at fraction 0, all traveled at fraction 1', () {
      final (doneA, remainingA) = RoutePathMath.splitAtFraction(
        points,
        cumulative,
        0,
      );
      expect(doneA, isEmpty);
      expect(remainingA, points);

      final (doneB, remainingB) = RoutePathMath.splitAtFraction(
        points,
        cumulative,
        1,
      );
      expect(doneB, points);
      expect(remainingB, isEmpty);
    });

    test('shares an interpolated cut point with no gap', () {
      final (done, remaining) = RoutePathMath.splitAtFraction(
        points,
        cumulative,
        0.5,
      );

      expect(done.last, remaining.first);
      expect(done.last.longitude, closeTo(1, 1e-2));
      expect(remaining.last, points.last);
    });
  });

  group('lerpHeading', () {
    test('crosses north via the shortest arc', () {
      final heading = RoutePathMath.lerpHeading(350, 10, 0.5);
      expect(heading % 360, closeTo(0, 1e-9));
    });

    test('interpolates plain angles linearly', () {
      expect(RoutePathMath.lerpHeading(40, 60, 0.5), closeTo(50, 1e-9));
    });

    test('returns endpoints at t=0 and t=1', () {
      expect(RoutePathMath.lerpHeading(350, 10, 0) % 360, closeTo(350, 1e-9));
      expect(RoutePathMath.lerpHeading(350, 10, 1) % 360, closeTo(10, 1e-9));
    });
  });
}
