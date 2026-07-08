import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/core/tracking/progress/arrival_events.dart';

void main() {
  group('countStationArrivalEvents', () {
    test('counts only the canonical arrival title', () {
      final count = countStationArrivalEvents([
        'وصول محطة',
        'مغادرة محطة',
        'وصول محطة',
        null,
        'تخطي محطة',
        'وصول محطة',
      ]);

      expect(count, 3);
    });

    test('returns 0 for an empty or non-matching event list', () {
      expect(countStationArrivalEvents(const []), 0);
      expect(countStationArrivalEvents(['غادرت الرحلة']), 0);
    });
  });

  group('stationArrivalFloor', () {
    test('passes through a count within range', () {
      final floor = stationArrivalFloor(
        arrivalEventCount: 2,
        routePointCount: 5,
      );

      expect(floor, 2);
    });

    test('clamps to the route point count so extra events cannot overflow', () {
      final floor = stationArrivalFloor(
        arrivalEventCount: 9,
        routePointCount: 4,
      );

      expect(floor, 4);
    });

    test('returns 0 when the route has no points', () {
      final floor = stationArrivalFloor(
        arrivalEventCount: 3,
        routePointCount: 0,
      );

      expect(floor, 0);
    });

    test('never goes negative for a negative count', () {
      final floor = stationArrivalFloor(
        arrivalEventCount: -1,
        routePointCount: 5,
      );

      expect(floor, 0);
    });
  });
}
