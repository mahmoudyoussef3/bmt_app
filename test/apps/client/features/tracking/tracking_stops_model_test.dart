import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/tracking/data/models/tracking_stops_model.dart';

/// Stop order is load-bearing: the map polyline, the progress engine's
/// along-route projection, and the rider's timeline all treat index order as
/// route order. One mis-ordered row silently corrupts distances, ETAs and stop
/// states at once — so the data layer sorts rather than trusting the response.
void main() {
  group('TrackingStopsModel.fromRows', () {
    test('orders stops by point_order, not by the order rows arrive in', () {
      final stops = TrackingStopsModel.fromRows([
        _row(name: 'Smart Village', order: 3),
        _row(name: 'Banha', order: 0),
        _row(name: 'Heliopolis', order: 2),
        _row(name: 'Nasr City', order: 1),
      ]);

      expect(
        stops.map((s) => s.name).toList(),
        ['Banha', 'Nasr City', 'Heliopolis', 'Smart Village'],
      );
      expect(stops.map((s) => s.order).toList(), [0, 1, 2, 3]);
    });

    test('keeps real coordinates and flags placeholder (0,0) stations', () {
      final stops = TrackingStopsModel.fromRows([
        _row(name: 'Banha', order: 0, lat: 30.46, lng: 31.18),
        _row(name: 'Unmapped', order: 1, lat: 0, lng: 0),
      ]);

      expect(stops.first.latitude, 30.46);
      expect(stops.first.hasCoordinates, isTrue);
      expect(stops.last.hasCoordinates, isFalse);
    });

    test('resolves per-stop clock times against the trip date', () {
      final departure = DateTime.parse('2026-07-15T08:00:00');
      final stops = TrackingStopsModel.fromRows(
        [_row(name: 'Banha', order: 0, arrival: '08:30')],
        tripDate: '2026-07-15',
        departureAt: departure,
      );

      expect(stops.first.plannedArrival, DateTime.parse('2026-07-15T08:30:00'));
    });

    test('rolls a stop past midnight forward a day on an overnight run', () {
      // Departs 23:00; the 01:30 stop belongs to the next calendar day, not to
      // 21.5 hours *before* the bus left.
      final departure = DateTime.parse('2026-07-15T23:00:00');
      final stops = TrackingStopsModel.fromRows(
        [_row(name: 'Aswan', order: 0, arrival: '01:30')],
        tripDate: '2026-07-15',
        departureAt: departure,
      );

      expect(stops.first.plannedArrival, DateTime.parse('2026-07-16T01:30:00'));
    });

    test('leaves times null when the dashboard configured none', () {
      final stops = TrackingStopsModel.fromRows(
        [_row(name: 'Banha', order: 0)],
        tripDate: '2026-07-15',
      );

      expect(stops.first.plannedArrival, isNull);
      expect(stops.first.plannedDeparture, isNull);
    });
  });
}

Map<String, dynamic> _row({
  required String name,
  required int order,
  double lat = 30.0,
  double lng = 31.0,
  String? arrival,
}) {
  return {
    'id': 'stop-$order',
    'route_point_id': 'rp-$order',
    'point_name': name,
    'point_order': order,
    'latitude': lat,
    'longitude': lng,
    'arrival_offset': arrival,
    'departure_offset': null,
  };
}
