import 'package:bmt_app/core/tracking/tracking.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const estimator = EtaEstimator(RouteProgressConfig());
  final now = DateTime.utc(2026, 7, 7, 10);

  group('effective speed', () {
    test('blends live speed with the reference pace while moving', () {
      final speed = estimator.effectiveSpeedKmh(
        liveSpeedKmh: 60,
        schedulePaceKmh: 40,
      );
      expect(speed, closeTo(60 * 0.7 + 40 * 0.3, 1e-9));
    });

    test('prefers the trip average over the schedule as reference', () {
      final speed = estimator.effectiveSpeedKmh(
        liveSpeedKmh: 60,
        tripAverageKmh: 50,
        schedulePaceKmh: 30,
      );
      expect(speed, closeTo(60 * 0.7 + 50 * 0.3, 1e-9));
    });

    test('ignores a dwelling live speed and falls back down the chain', () {
      expect(
        estimator.effectiveSpeedKmh(liveSpeedKmh: 2, tripAverageKmh: 44),
        44,
      );
      expect(estimator.effectiveSpeedKmh(liveSpeedKmh: 2), 35); // fallback
    });

    test('clamps outliers into the sane band', () {
      expect(estimator.effectiveSpeedKmh(liveSpeedKmh: 300), 90);
      expect(estimator.effectiveSpeedKmh(tripAverageKmh: 4), 12);
    });
  });

  group('fromDistance', () {
    test('adds travel time plus dwell per intermediate stop', () {
      final estimate = estimator.fromDistance(
        remainingMeters: 10000,
        intermediateStops: 2,
        now: now,
        liveSpeedKmh: 60,
      );
      // 10 km at 60 km/h = 600 s, plus 2 × 45 s of dwell.
      expect(estimate.eta, now.add(const Duration(seconds: 690)));
      expect(estimate.confidence, EtaConfidence.live);
    });

    test('reports estimated confidence when the vehicle is dwelling', () {
      final estimate = estimator.fromDistance(
        remainingMeters: 3500,
        intermediateStops: 0,
        now: now,
        liveSpeedKmh: 0,
      );
      // Falls back to 35 km/h: 3.5 km → 360 s.
      expect(estimate.eta, now.add(const Duration(seconds: 360)));
      expect(estimate.confidence, EtaConfidence.estimated);
    });
  });

  group('fromSchedule', () {
    test('surfaces the published plan with scheduled confidence', () {
      final planned = now.add(const Duration(minutes: 25));
      final estimate = estimator.fromSchedule(planned);
      expect(estimate.eta, planned);
      expect(estimate.confidence, EtaConfidence.scheduled);
    });

    test('yields none without a plan', () {
      expect(estimator.fromSchedule(null).confidence, EtaConfidence.none);
      expect(estimator.fromSchedule(null).eta, isNull);
    });
  });
}
