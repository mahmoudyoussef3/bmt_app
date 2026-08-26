import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/trips/data/mappers/trip_stop_mapper.dart';

/// The two traps this mapper exists to avoid: index order that isn't route
/// order, and the id-space gap between what a booking stores
/// (`route_stations.id`) and what a trip's own stop rows are keyed by.

Map<String, dynamic> _row({
  required String id,
  required String stationId,
  required String name,
  required int order,
}) {
  return {
    'id': id,
    'route_point_id': stationId,
    'point_name': name,
    'point_order': order,
    'arrival_offset': '0$order:00',
    'departure_offset': '0$order:05',
  };
}

void main() {
  final rows = [
    _row(id: 'p2', stationId: 's2', name: 'Tanta', order: 2),
    _row(id: 'p0', stationId: 's0', name: 'Cairo', order: 0),
    _row(id: 'p1', stationId: 's1', name: 'Banha', order: 1),
  ];

  test(
    'stops come back in running order, whatever order the rows arrived in',
    () {
      final stops = TripStopMapper.fromRows(rows);

      expect(stops.map((stop) => stop.name), ['Cairo', 'Banha', 'Tanta']);
    },
  );

  test("the rider's stops are matched by the route station id", () {
    final stops = TripStopMapper.fromRows(
      rows,
      pickupPointId: 's1',
      dropoffPointId: 's2',
      // Names that would match the wrong rows, to prove the id wins.
      pickupPointName: 'Cairo',
      dropoffPointName: 'Cairo',
    );

    expect(stops[1].isBoarding, isTrue);
    expect(stops[2].isDropoff, isTrue);
    expect(stops[0].isMine, isFalse);
  });

  test('a booking whose stored ids match nothing falls back to the names', () {
    final stops = TripStopMapper.fromRows(
      rows,
      pickupPointId: 'from-another-snapshot',
      dropoffPointId: 'from-another-snapshot',
      pickupPointName: ' banha ',
      dropoffPointName: 'Tanta',
    );

    expect(stops[1].isBoarding, isTrue);
    expect(stops[2].isDropoff, isTrue);
  });

  test('a booking with neither id nor name badges nothing', () {
    final stops = TripStopMapper.fromRows(rows);

    expect(stops.any((stop) => stop.isMine), isFalse);
  });

  test(
    'offsets are carried through untouched — they are durations, not clocks',
    () {
      final stops = TripStopMapper.fromRows(rows);

      expect(stops[2].arrivalOffset, '02:00');
      expect(stops[2].departureOffset, '02:05');
    },
  );
}
