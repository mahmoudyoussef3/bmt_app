import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/operation_trip.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_management/presentation/cubit/trips_list_cubit.dart';

// Regression coverage for the "dashboard says three trips are open for booking
// but the client app only offers one" bug. The client only sells trips with
// `trip_date >= today`, while the dashboard filtered on status alone — so a
// trip left on `open_for_booking` after its departure day kept being counted as
// upcoming inventory that no passenger could actually see.

String _isoDate(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

OperationTrip _trip(
  String id, {
  required String date,
  OperationTripStatus status = OperationTripStatus.openForBooking,
}) {
  return OperationTrip(
    id: id,
    routeId: 'route-1',
    route: 'بنها - القرية الذكية',
    routePoints: const [],
    driverId: 'driver-1',
    driver: 'أحمد حسن',
    vehicleId: 'vehicle-1',
    vehicle: 'ق س أ 1234',
    date: date,
    departure: '09:00',
    arrival: '10:30',
    status: status,
    capacity: 14,
    seats: const [],
    passengers: const [],
    events: const [],
    notes: const [],
  );
}

void main() {
  final now = DateTime.now();
  final today = _isoDate(now);
  final yesterday = _isoDate(now.subtract(const Duration(days: 1)));
  final threeDaysAgo = _isoDate(now.subtract(const Duration(days: 3)));
  final tomorrow = _isoDate(now.add(const Duration(days: 1)));

  group('OperationTrip.isStaleBooking', () {
    final reference = DateTime(2026, 7, 14);

    test('flags a bookable trip whose departure day has passed', () {
      final trip = _trip('t1', date: '2026-07-11');
      expect(trip.isStaleBooking(now: reference), isTrue);
    });

    test('flags a scheduled trip whose departure day has passed', () {
      final trip = _trip(
        't1',
        date: '2026-07-11',
        status: OperationTripStatus.scheduled,
      );
      expect(trip.isStaleBooking(now: reference), isTrue);
    });

    test('does not flag a trip departing today', () {
      final trip = _trip('t1', date: '2026-07-14');
      expect(trip.isStaleBooking(now: reference), isFalse);
    });

    test('does not flag a future trip', () {
      final trip = _trip('t1', date: '2026-07-20');
      expect(trip.isStaleBooking(now: reference), isFalse);
    });

    test('does not flag past trips that were already resolved', () {
      for (final status in [
        OperationTripStatus.completed,
        OperationTripStatus.cancelled,
        OperationTripStatus.inProgress,
        OperationTripStatus.boarding,
      ]) {
        final trip = _trip('t1', date: '2026-07-11', status: status);
        expect(
          trip.isStaleBooking(now: reference),
          isFalse,
          reason: 'status $status should not be reported as stale',
        );
      }
    });

    test('does not flag a trip with an unparsable date', () {
      final trip = _trip('t1', date: 'not-a-date');
      expect(trip.isStaleBooking(now: reference), isFalse);
    });
  });

  group('TripsListLoaded — three open trips, two of them past-dated', () {
    final state = TripsListLoaded(
      trips: [
        _trip('past-1', date: threeDaysAgo),
        _trip('past-2', date: yesterday),
        _trip('today-1', date: today),
      ],
    );

    test('counts only the trip a passenger can actually book as upcoming', () {
      expect(state.upcomingTrips, 1);
    });

    test('surfaces the two past-dated open trips for review', () {
      expect(state.staleTrips, 2);
    });

    test('the stale filter lists exactly the past-dated open trips', () {
      final filtered = state
          .copyWith(quickFilter: 'stale')
          .filteredTrips
          .map((trip) => trip.id)
          .toList();
      expect(filtered, ['past-1', 'past-2']);
    });

    test('the upcoming filter hides past-dated open trips', () {
      final filtered = state
          .copyWith(quickFilter: 'upcoming')
          .filteredTrips
          .map((trip) => trip.id)
          .toList();
      expect(filtered, ['today-1']);
    });
  });

  group('TripsListLoaded — healthy inventory', () {
    final state = TripsListLoaded(
      trips: [
        _trip('today-1', date: today),
        _trip('tomorrow-1', date: tomorrow),
      ],
    );

    test('reports no trips needing review', () {
      expect(state.staleTrips, 0);
      expect(state.upcomingTrips, 2);
    });
  });
}
