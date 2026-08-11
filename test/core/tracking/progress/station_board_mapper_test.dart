import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/core/tracking/progress/station_board.dart';
import 'package:bmt_app/core/tracking/progress/station_board_mapper.dart';

/// The mapper is shared by both apps precisely so they cannot disagree about
/// what a row means. A dwell parsed as minutes on one side and seconds on the
/// other would put the two apps into different answers to "can the vehicle
/// leave?", so the units are asserted explicitly.
void main() {
  test('maps a full row, including the units the gate depends on', () {
    final board = StationBoardMapper.fromRows([
      _row(
        sequence: 1,
        minDwellSeconds: 180,
        expectedArrival: '2026-08-11T06:30:00Z',
        actualArrival: '2026-08-11T06:38:00Z',
      ),
    ]);

    final station = board.stations.single;
    expect(station.id, 'st-1');
    expect(station.name, 'محطة بنها');
    expect(station.sequence, 1);
    expect(station.routePointId, 'rp-1');
    expect(station.minDwell, const Duration(minutes: 3));
    expect(station.expectedBoardings, 3);
    expect(station.boardedCount, 2);
    expect(station.pendingCount, 1);
    expect(station.status, TripStationStatus.waitingForPassengers);
    expect(
      station.expectedArrivalAt,
      DateTime.utc(2026, 8, 11, 6, 30).toLocal(),
      reason: 'timestamps arrive in UTC and every surface renders wall clock',
    );
    expect(station.actualArrivalAt, DateTime.utc(2026, 8, 11, 6, 38).toLocal());
  });

  test('sorts by sequence rather than trusting the order rows arrived in', () {
    final board = StationBoardMapper.fromRows([
      _row(sequence: 3, name: 'C'),
      _row(sequence: 1, name: 'A'),
      _row(sequence: 2, name: 'B'),
    ]);

    expect(
      board.stations.map((s) => s.name),
      ['A', 'B', 'C'],
      reason: 'index order is route order for every consumer downstream',
    );
  });

  test('a sparse row degrades to nulls and zeroes instead of throwing', () {
    final board = StationBoardMapper.fromRows([
      {'id': 'st-1', 'point_name': 'محطة', 'sequence': 1},
    ]);

    final station = board.stations.single;
    expect(station.expectedArrivalAt, isNull);
    expect(station.actualArrivalAt, isNull);
    expect(station.minDwell, Duration.zero);
    expect(station.expectedBoardings, 0);
    expect(station.status, TripStationStatus.upcoming);
    expect(station.earliestDeparture, isNull);
  });

  test('numeric columns survive arriving as strings', () {
    final board = StationBoardMapper.fromRows([
      {
        'id': 'st-1',
        'point_name': 'محطة',
        'sequence': '2',
        'min_dwell_seconds': '300',
        'pending_count': '4',
      },
    ]);

    final station = board.stations.single;
    expect(station.sequence, 2);
    expect(station.minDwell, const Duration(minutes: 5));
    expect(station.pendingCount, 4);
  });

  test('no rows is an empty board, not a crash', () {
    expect(StationBoardMapper.fromRows(const []).isEmpty, isTrue);
  });

  test('the select list names every column the mapper reads', () {
    // The one guard against a column being added here and forgotten in the
    // query — the row would silently map to a default and the gate would be
    // wrong rather than broken.
    for (final column in const [
      'sequence',
      'point_name',
      'route_point_id',
      'expected_arrival_at',
      'expected_departure_at',
      'min_dwell_seconds',
      'actual_arrival_at',
      'actual_departure_at',
      'status',
      'expected_boardings',
      'boarded_count',
      'pending_count',
      'no_show_count',
    ]) {
      expect(StationBoardMapper.columns, contains(column));
    }
  });
}

Map<String, dynamic> _row({
  required int sequence,
  String name = 'محطة بنها',
  int minDwellSeconds = 0,
  String? expectedArrival,
  String? actualArrival,
}) {
  return {
    'id': 'st-$sequence',
    'trip_id': 'trip-1',
    'route_point_id': 'rp-$sequence',
    'point_name': name,
    'sequence': sequence,
    'expected_arrival_at': expectedArrival,
    'expected_departure_at': null,
    'min_dwell_seconds': minDwellSeconds,
    'actual_arrival_at': actualArrival,
    'actual_departure_at': null,
    'status': 'waiting_for_passengers',
    'expected_boardings': 3,
    'boarded_count': 2,
    'pending_count': 1,
    'no_show_count': 0,
  };
}
