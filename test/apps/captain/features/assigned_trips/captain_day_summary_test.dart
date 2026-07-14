import 'package:bmt_app/apps/captain/features/assigned_trips/domain/entities/assigned_trip.dart';
import 'package:bmt_app/apps/captain/features/assigned_trips/domain/entities/captain_day_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CaptainDaySummary', () {
    test('has no focus trip and is not complete when nothing is assigned', () {
      final summary = CaptainDaySummary.fromTrips(const []);

      expect(summary.isEmpty, isTrue);
      expect(summary.isDayComplete, isFalse);
      expect(summary.focusTrip, isNull);
      expect(summary.boardingProgress, 0);
    });

    test('focuses the earliest scheduled trip', () {
      final summary = CaptainDaySummary.fromTrips([
        _trip(id: 'late', hour: 15),
        _trip(id: 'early', hour: 8),
      ]);

      expect(summary.focusTrip?.id, 'early');
      expect(summary.activeTrips, 0);
    });

    test('a running trip outranks an earlier scheduled one', () {
      final summary = CaptainDaySummary.fromTrips([
        _trip(id: 'scheduled', hour: 6),
        _trip(id: 'running', hour: 14, status: AssignedTripStatus.inProgress),
      ]);

      expect(summary.focusTrip?.id, 'running');
      expect(summary.activeTrips, 1);
    });

    test('boarding counts as running', () {
      final summary = CaptainDaySummary.fromTrips([
        _trip(id: 'boarding', hour: 9, status: AssignedTripStatus.boarding),
      ]);

      expect(summary.focusTrip?.id, 'boarding');
      expect(summary.activeTrips, 1);
    });

    test('reports the day complete once every trip is finished', () {
      final summary = CaptainDaySummary.fromTrips([
        _trip(id: 'a', hour: 8, status: AssignedTripStatus.completed),
        _trip(id: 'b', hour: 12, status: AssignedTripStatus.completed),
      ]);

      expect(summary.focusTrip, isNull);
      expect(summary.isDayComplete, isTrue);
      expect(summary.isEmpty, isFalse);
      expect(summary.totalTrips, 2);
    });

    test('aggregates passengers and boarding progress across trips', () {
      final summary = CaptainDaySummary.fromTrips([
        _trip(id: 'a', hour: 8, passengers: 20, boarded: 5),
        _trip(id: 'b', hour: 12, passengers: 20, boarded: 15),
      ]);

      expect(summary.passengers, 40);
      expect(summary.boarded, 20);
      expect(summary.boardingProgress, 0.5);
    });
  });
}

AssignedTrip _trip({
  required String id,
  required int hour,
  AssignedTripStatus status = AssignedTripStatus.scheduled,
  int passengers = 10,
  int boarded = 0,
}) {
  final departure = DateTime(2026, 7, 14, hour);
  return AssignedTrip(
    id: id,
    route: 'القاهرة - الإسكندرية',
    vehicleNumber: 'BUS-1',
    plateNumber: 'أ ب ج 123',
    departureTime: departure,
    expectedArrivalTime: departure.add(const Duration(hours: 3)),
    stops: const [],
    passengerCount: passengers,
    boardedCount: boarded,
    status: status,
  );
}
