import 'package:bmt_app/core/tracking/tracking.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime.utc(2026, 7, 6, 10);

  VehicleFix fix({
    double lat = 30.0,
    int secondsAfterT0 = 0,
    double? speedMps,
  }) {
    return VehicleFix(
      latitude: lat,
      longitude: 31.0,
      recordedAt: t0.add(Duration(seconds: secondsAfterT0)),
      speedMetersPerSecond: speedMps,
    );
  }

  test('uses the device speed converted to km/h', () {
    final estimator = SpeedEstimator(const TrackingConfig());
    expect(estimator.update(null, fix(speedMps: 10)), closeTo(36, 0.001));
  });

  test('smooths successive device speeds exponentially', () {
    final estimator = SpeedEstimator(const TrackingConfig());
    estimator.update(null, fix(speedMps: 10)); // 36 km/h
    final second = estimator.update(
      fix(speedMps: 10),
      fix(speedMps: 20, secondsAfterT0: 5), // raw 72 km/h
    );
    // 0.35 * 72 + 0.65 * 36 = 48.6
    expect(second, closeTo(48.6, 0.001));
    expect(estimator.currentKmh, closeTo(48.6, 0.001));
  });

  test('derives speed from displacement when the device omits it', () {
    final estimator = SpeedEstimator(const TrackingConfig());
    final previous = fix();
    // ~111.2 m north in 10 s ⇒ ~11.12 m/s ⇒ ~40 km/h.
    final next = fix(lat: 30.001, secondsAfterT0: 10);
    final kmh = estimator.update(previous, next);
    expect(kmh, closeTo(40.03, 0.5));
  });

  test('treats a negative device speed as missing', () {
    final estimator = SpeedEstimator(const TrackingConfig());
    final previous = fix();
    final next = fix(lat: 30.001, secondsAfterT0: 10, speedMps: -1);
    expect(estimator.update(previous, next), closeTo(40.03, 0.5));
  });

  test('returns 0 with no device speed and no previous fix', () {
    final estimator = SpeedEstimator(const TrackingConfig());
    expect(estimator.update(null, fix()), 0);
  });

  test('reset clears the smoothed estimate', () {
    final estimator = SpeedEstimator(const TrackingConfig());
    estimator.update(null, fix(speedMps: 10));
    estimator.reset();
    expect(estimator.currentKmh, 0);
  });
}
