import 'package:bmt_app/core/tracking/tracking.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final rec0 = DateTime.utc(2026, 7, 6, 10);
  final now0 = DateTime.utc(2026, 7, 6, 10, 0, 30);

  VehicleFix fix({
    double lat = 30.0,
    double lng = 31.0,
    int secondsAfterRec0 = 0,
    double? heading,
    double? speedMps,
    double? accuracy,
  }) {
    return VehicleFix(
      latitude: lat,
      longitude: lng,
      recordedAt: rec0.add(Duration(seconds: secondsAfterRec0)),
      headingDegrees: heading,
      speedMetersPerSecond: speedMps,
      accuracyMeters: accuracy,
    );
  }

  VehicleTrackingEngine engine() =>
      VehicleTrackingEngine(easing: (t) => t); // linear ⇒ exact midpoints

  test('has no sample before any fix', () {
    expect(engine().sample(now0), isNull);
  });

  test('snaps to the first fix without interpolating', () {
    final e = engine();
    expect(e.addFix(fix(accuracy: 12), now: now0), isTrue);
    final s = e.sample(now0)!;
    expect(s.latitude, 30.0);
    expect(s.longitude, 31.0);
    expect(s.accuracyMeters, 12);
    expect(s.isInterpolating, isFalse);
  });

  test('interpolates linearly between two fixes over the fix interval', () {
    final e = engine();
    e.addFix(fix(), now: now0);
    // ~111 m in 4 s ≈ 100 km/h: a plausible highway move.
    final later = now0.add(const Duration(seconds: 4));
    expect(e.addFix(fix(lat: 30.001, secondsAfterRec0: 4), now: later), isTrue);

    expect(e.sample(later)!.latitude, closeTo(30.0, 1e-9));
    expect(e.isAnimating(later), isTrue);

    final halfway = later.add(const Duration(seconds: 2));
    expect(e.sample(halfway)!.latitude, closeTo(30.0005, 1e-9));
    expect(e.sample(halfway)!.isInterpolating, isTrue);

    final done = later.add(const Duration(seconds: 4));
    expect(e.sample(done)!.latitude, closeTo(30.001, 1e-9));
    expect(e.sample(done)!.isInterpolating, isFalse);
    expect(e.isAnimating(done), isFalse);
  });

  test('a fix arriving mid-animation continues from the interpolated '
      'position without jumping', () {
    final e = engine();
    e.addFix(fix(), now: now0);
    final second = now0.add(const Duration(seconds: 4));
    expect(
      e.addFix(fix(lat: 30.001, secondsAfterRec0: 4), now: second),
      isTrue,
    );

    final midFlight = second.add(const Duration(seconds: 2)); // at 30.0005
    expect(
      e.addFix(fix(lat: 30.002, secondsAfterRec0: 8), now: midFlight),
      isTrue,
    );

    // Immediately after the new fix the marker is exactly where it was.
    expect(e.sample(midFlight)!.latitude, closeTo(30.0005, 1e-9));

    // And it eases towards the new target from there.
    final arrived = midFlight.add(const Duration(seconds: 4));
    expect(e.sample(arrived)!.latitude, closeTo(30.002, 1e-9));
  });

  test('clamps the animation window for sparse fixes', () {
    final e = engine();
    e.addFix(fix(), now: now0);
    final muchLater = now0.add(const Duration(seconds: 60));
    // ~550 m in 60 s: plausible, below the snap distance.
    e.addFix(fix(lat: 30.005, secondsAfterRec0: 60), now: muchLater);

    // Default maxAnimation is 6 s — the marker must have arrived by then.
    final afterMax = muchLater.add(const Duration(seconds: 6));
    expect(e.sample(afterMax)!.latitude, closeTo(30.005, 1e-9));
    expect(e.isAnimating(afterMax), isFalse);
  });

  test('teleports instead of crawling across long jumps', () {
    final e = engine();
    e.addFix(fix(), now: now0);
    final later = now0.add(const Duration(minutes: 5));
    // ~11 km in 300 s ⇒ ~37 m/s: plausible but far beyond snapDistance.
    e.addFix(fix(lat: 30.1, secondsAfterRec0: 300), now: later);

    final s = e.sample(later)!;
    expect(s.latitude, closeTo(30.1, 1e-9));
    expect(s.isInterpolating, isFalse);
  });

  test('rejects out-of-order fixes and keeps the current target', () {
    final e = engine();
    e.addFix(fix(secondsAfterRec0: 10), now: now0);
    final accepted = e.addFix(
      fix(lat: 30.5, secondsAfterRec0: 5),
      now: now0.add(const Duration(seconds: 1)),
    );
    expect(accepted, isFalse);
    expect(e.lastRejection, FixRejection.outOfOrder);
    expect(e.targetFix!.latitude, 30.0);
  });

  test('flags the sample stale when no fix arrives within the window', () {
    final e = engine();
    e.addFix(fix(), now: now0);
    expect(e.sample(now0.add(const Duration(minutes: 1)))!.isStale, isFalse);
    expect(e.sample(now0.add(const Duration(minutes: 3)))!.isStale, isTrue);
  });

  test('interpolates the accuracy circle radius between fixes', () {
    final e = engine();
    e.addFix(fix(accuracy: 10), now: now0);
    final later = now0.add(const Duration(seconds: 4));
    expect(
      e.addFix(fix(lat: 30.001, secondsAfterRec0: 4, accuracy: 20), now: later),
      isTrue,
    );

    final halfway = later.add(const Duration(seconds: 2));
    expect(e.sample(halfway)!.accuracyMeters, closeTo(15, 1e-9));
  });

  test('rotates the heading along the shortest arc between fixes', () {
    final e = engine();
    e.addFix(fix(heading: 350, speedMps: 10), now: now0);
    final later = now0.add(const Duration(seconds: 2));
    e.addFix(
      fix(lat: 30.0002, secondsAfterRec0: 2, heading: 10, speedMps: 10),
      now: later,
    );

    final halfway = later.add(const Duration(seconds: 1));
    expect(e.sample(halfway)!.headingDegrees, closeTo(0, 0.001));
  });

  test('surfaces smoothed speed and motion state on the sample', () {
    final e = engine();
    e.addFix(fix(speedMps: 10), now: now0);
    final s = e.sample(now0)!;
    expect(s.speedKmh, closeTo(36, 0.001));
    expect(s.isMoving, isTrue);

    e.reset();
    expect(e.sample(now0), isNull);
  });
}
