import 'package:bmt_app/core/tracking/geo_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GeoMath.distanceMeters', () {
    test('is zero for identical points', () {
      expect(GeoMath.distanceMeters(30.0, 31.0, 30.0, 31.0), 0);
    });

    test('one degree of latitude is ~111.2 km', () {
      final d = GeoMath.distanceMeters(30.0, 31.0, 31.0, 31.0);
      expect(d, closeTo(111195, 200));
    });

    test('is symmetric', () {
      final ab = GeoMath.distanceMeters(30.0, 31.0, 30.5, 31.5);
      final ba = GeoMath.distanceMeters(30.5, 31.5, 30.0, 31.0);
      expect(ab, closeTo(ba, 0.0001));
    });
  });

  group('GeoMath.bearingDegrees', () {
    test('due north is 0°', () {
      expect(GeoMath.bearingDegrees(30.0, 31.0, 31.0, 31.0), closeTo(0, 0.01));
    });

    test('due east on the equator is 90°', () {
      expect(GeoMath.bearingDegrees(0, 31.0, 0, 32.0), closeTo(90, 0.01));
    });

    test('due south is 180°', () {
      expect(
        GeoMath.bearingDegrees(31.0, 31.0, 30.0, 31.0),
        closeTo(180, 0.01),
      );
    });

    test('due west on the equator is 270°', () {
      expect(GeoMath.bearingDegrees(0, 32.0, 0, 31.0), closeTo(270, 0.01));
    });
  });

  group('GeoMath.normalizeDegrees', () {
    test('wraps values into [0, 360)', () {
      expect(GeoMath.normalizeDegrees(-90), 270);
      expect(GeoMath.normalizeDegrees(450), 90);
      expect(GeoMath.normalizeDegrees(360), 0);
      expect(GeoMath.normalizeDegrees(0), 0);
    });
  });

  group('GeoMath.lerpAngleDegrees', () {
    test('takes the short arc across north (350° → 10°)', () {
      expect(GeoMath.lerpAngleDegrees(350, 10, 0.5), closeTo(0, 0.001));
    });

    test('takes the short arc across north (10° → 350°)', () {
      expect(GeoMath.lerpAngleDegrees(10, 350, 0.5), closeTo(0, 0.001));
    });

    test('interpolates plain angles linearly', () {
      expect(GeoMath.lerpAngleDegrees(0, 90, 0.5), closeTo(45, 0.001));
    });

    test('returns endpoints at t=0 and t=1', () {
      expect(GeoMath.lerpAngleDegrees(30, 200, 0), closeTo(30, 0.001));
      expect(GeoMath.lerpAngleDegrees(30, 200, 1), closeTo(200, 0.001));
    });
  });

  group('GeoMath.lerpLongitude', () {
    test('crosses the antimeridian the short way', () {
      final mid = GeoMath.lerpLongitude(179, -179, 0.5);
      expect(mid.abs(), closeTo(180, 0.001));
    });

    test('interpolates ordinary longitudes linearly', () {
      expect(GeoMath.lerpLongitude(31.0, 32.0, 0.25), closeTo(31.25, 1e-9));
    });
  });

  group('GeoMath.easeOutCubic', () {
    test('anchors at 0 and 1 and stays monotonic', () {
      expect(GeoMath.easeOutCubic(0), 0);
      expect(GeoMath.easeOutCubic(1), closeTo(1, 1e-9));
      var previous = 0.0;
      for (var t = 0.0; t <= 1.0; t += 0.05) {
        final v = GeoMath.easeOutCubic(t);
        expect(v, greaterThanOrEqualTo(previous));
        previous = v;
      }
    });
  });
}
