import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/core/utils/bookable_trip.dart';
import 'package:bmt_app/apps/client/features/routes/data/models/route_availability_model.dart';
import 'package:bmt_app/apps/client/features/routes/domain/entities/route_availability.dart';

String _today() => BookableTrip.today();

String _daysFromToday(int days) =>
    DateTime.now().add(Duration(days: days)).toIso8601String().split('T').first;

/// A `public_trips` row as the catalog reads it: seats come from the
/// `trip_seats` embed, never from the `booked_seats` counter, which has read 0
/// since the booking flow was rewritten.
Map<String, dynamic> _trip({
  String routeId = 'r1',
  String? date,
  String time = '08:00:00',
  int seatsFree = 3,
  int seatsTaken = 0,
  String status = 'open_for_booking',
}) {
  return {
    'route_id': routeId,
    'trip_date': date ?? _today(),
    'departure_time': time,
    'status': status,
    'capacity': seatsFree + seatsTaken,
    'booked_seats': 0,
    'trip_seats': [
      for (var i = 0; i < seatsFree; i++) {'state': 'available'},
      for (var i = 0; i < seatsTaken; i++) {'state': 'paid'},
    ],
  };
}

void main() {
  group('RouteAvailabilityModel.fromTrips', () {
    test('a departure with free seats is bookable', () {
      final availability = RouteAvailabilityModel.fromTrips([
        _trip(seatsFree: 4),
      ]);

      expect(availability.status, RouteAvailabilityStatus.bookable);
      expect(availability.isBookable, isTrue);
      expect(availability.seatsLeft, 4);
      expect(availability.tripCount, 1);
    });

    test('departures with every seat taken read as sold out, not as none', () {
      final availability = RouteAvailabilityModel.fromTrips([
        _trip(seatsFree: 0, seatsTaken: 14),
      ]);

      expect(availability.status, RouteAvailabilityStatus.soldOut);
      expect(availability.seatsLeft, 0);
      expect(availability.tripCount, 0);
    });

    test('names the first departure a rider could take, not the first row', () {
      final availability = RouteAvailabilityModel.fromTrips([
        _trip(time: '06:00:00', seatsFree: 0, seatsTaken: 14),
        _trip(time: '09:00:00', seatsFree: 2),
      ]);

      expect(availability.status, RouteAvailabilityStatus.bookable);
      expect(availability.nextDepartureTime, '09:00:00');
      expect(availability.seatsLeft, 2);
    });

    test('a sold-out corridor still says when its buses run', () {
      final availability = RouteAvailabilityModel.fromTrips([
        _trip(time: '06:00:00', seatsFree: 0, seatsTaken: 14),
        _trip(time: '09:00:00', seatsFree: 0, seatsTaken: 14),
      ]);

      expect(availability.status, RouteAvailabilityStatus.soldOut);
      expect(availability.nextDepartureTime, '06:00:00');
    });

    test('counts only the departures that still have a seat', () {
      final availability = RouteAvailabilityModel.fromTrips([
        _trip(time: '06:00:00', seatsFree: 1),
        _trip(time: '09:00:00', seatsFree: 0, seatsTaken: 14),
        _trip(time: '18:00:00', seatsFree: 5),
      ]);

      expect(availability.tripCount, 2);
    });

    test('no departures at all is none', () {
      final availability = RouteAvailabilityModel.fromTrips(const []);

      expect(availability.status, RouteAvailabilityStatus.none);
      expect(availability.isKnown, isTrue);
    });
  });

  group('RouteAvailabilityModel.byRouteId', () {
    test('summarises each corridor separately', () {
      final byRoute = RouteAvailabilityModel.byRouteId([
        _trip(routeId: 'r1', seatsFree: 3),
        _trip(routeId: 'r2', seatsFree: 0, seatsTaken: 14),
      ]);

      expect(byRoute['r1']!.status, RouteAvailabilityStatus.bookable);
      expect(byRoute['r2']!.status, RouteAvailabilityStatus.soldOut);
    });

    test('a corridor with nothing on sale is simply absent', () {
      final byRoute = RouteAvailabilityModel.byRouteId([
        _trip(routeId: 'r1', seatsFree: 3),
      ]);

      expect(byRoute.containsKey('r2'), isFalse);
    });

    test('drops departures that have already sailed', () {
      final byRoute = RouteAvailabilityModel.byRouteId([
        _trip(routeId: 'r1', date: _daysFromToday(-1)),
      ]);

      expect(byRoute, isEmpty);
    });

    test('drops rows the booking RPC would refuse', () {
      final byRoute = RouteAvailabilityModel.byRouteId([
        _trip(routeId: 'r1', status: 'in_progress'),
        _trip(routeId: 'r2', status: 'completed'),
      ]);

      expect(byRoute, isEmpty);
    });

    test('keeps a future departure', () {
      final byRoute = RouteAvailabilityModel.byRouteId([
        _trip(routeId: 'r1', date: _daysFromToday(9), seatsFree: 2),
      ]);

      expect(byRoute['r1']!.status, RouteAvailabilityStatus.bookable);
      expect(byRoute['r1']!.nextDepartureDate, _daysFromToday(9));
    });

    test('ignores a row with no route on it', () {
      final row = _trip()..remove('route_id');

      expect(RouteAvailabilityModel.byRouteId([row]), isEmpty);
    });
  });
}
