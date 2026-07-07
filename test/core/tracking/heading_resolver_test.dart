import 'package:bmt_app/core/tracking/tracking.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime.utc(2026, 7, 6, 10);

  VehicleFix fix({
    double lat = 30.0,
    double lng = 31.0,
    int secondsAfterT0 = 0,
    double? heading,
  }) {
    return VehicleFix(
      latitude: lat,
      longitude: lng,
      recordedAt: t0.add(Duration(seconds: secondsAfterT0)),
      headingDegrees: heading,
    );
  }

  test('trusts the device heading while moving', () {
    final resolver = HeadingResolver(const TrackingConfig());
    expect(resolver.resolve(null, fix(heading: 45), 60), 45);
  });

  test('normalizes device headings into [0, 360)', () {
    final resolver = HeadingResolver(const TrackingConfig());
    expect(resolver.resolve(null, fix(heading: 370), 60), closeTo(10, 0.001));
  });

  test('ignores the device heading while stationary and derives the path '
      'bearing instead', () {
    final resolver = HeadingResolver(const TrackingConfig());
    final previous = fix();
    // Due-north displacement of ~111 m with a bogus device heading.
    final next = fix(lat: 30.001, secondsAfterT0: 10, heading: 265);
    expect(resolver.resolve(previous, next, 0), closeTo(0, 0.1));
  });

  test('falls back to the path bearing when the device omits heading', () {
    final resolver = HeadingResolver(const TrackingConfig());
    final previous = fix();
    final next = fix(lng: 31.001, secondsAfterT0: 10); // due east
    expect(resolver.resolve(previous, next, 60), closeTo(90, 0.5));
  });

  test('holds the last heading through stationary GPS jitter', () {
    final resolver = HeadingResolver(const TrackingConfig());
    resolver.resolve(null, fix(heading: 120), 60);
    // ~1 m displacement: below the bearing threshold, no device heading.
    final jitter = fix(lat: 30.00001, secondsAfterT0: 10);
    expect(resolver.resolve(fix(), jitter, 0), 120);
  });

  test('negative device heading means missing (Geolocator convention)', () {
    final resolver = HeadingResolver(const TrackingConfig());
    resolver.resolve(null, fix(heading: 90), 60);
    final next = fix(secondsAfterT0: 10, heading: -1);
    expect(resolver.resolve(null, next, 60), 90);
  });

  test('reset returns heading to north', () {
    final resolver = HeadingResolver(const TrackingConfig());
    resolver.resolve(null, fix(heading: 90), 60);
    resolver.reset();
    expect(resolver.currentHeading, 0);
  });
}
