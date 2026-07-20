import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/captain/core/trips/captain_trip_stage.dart';
import 'package:bmt_app/apps/captain/features/assigned_trips/domain/entities/assigned_trip.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/domain/entities/trip_execution_state.dart';

/// Two gates stand between an assigned trip and a boarding captain:
/// operations publishing it, and the departure clock coming round. These
/// tests pin both, because collapsing them is what let the app offer
/// "بدء الرحلة" on a trip nobody could book yet.
void main() {
  final departure = DateTime(2026, 7, 20, 14);

  group('AssignedTrip.stageAt', () {
    test('a trip operations has not published is waiting on the dashboard, '
        'however close its departure is', () {
      final trip = _trip(departure, AssignedTripStatus.scheduled);

      // One minute before departure — the clock is no help while the trip is
      // still an internal draft.
      expect(
        trip.stageAt(departure.subtract(const Duration(minutes: 1))),
        CaptainTripStage.awaitingRelease,
      );
    });

    test('a published trip is not boardable until the boarding window', () {
      final trip = _trip(departure, AssignedTripStatus.openForBooking);
      final justOutside = departure
          .subtract(kCaptainBoardingWindow)
          .subtract(const Duration(minutes: 1));

      expect(trip.stageAt(justOutside), CaptainTripStage.awaitingWindow);
    });

    test('a published trip becomes boardable exactly at the window edge', () {
      final trip = _trip(departure, AssignedTripStatus.openForBooking);

      expect(
        trip.stageAt(departure.subtract(kCaptainBoardingWindow)),
        CaptainTripStage.readyToBoard,
      );
    });

    test('a late departure stays boardable rather than expiring', () {
      final trip = _trip(departure, AssignedTripStatus.openForBooking);

      expect(
        trip.stageAt(departure.add(const Duration(hours: 2))),
        CaptainTripStage.readyToBoard,
      );
    });

    test('running and finished states ignore the clock entirely', () {
      final early = departure.subtract(const Duration(hours: 6));

      expect(
        _trip(departure, AssignedTripStatus.boarding).stageAt(early),
        CaptainTripStage.boarding,
      );
      expect(
        _trip(departure, AssignedTripStatus.inProgress).stageAt(early),
        CaptainTripStage.underway,
      );
      expect(
        _trip(departure, AssignedTripStatus.completed).stageAt(early),
        CaptainTripStage.finished,
      );
    });
  });

  group('TripExecutionStatus.stageAt', () {
    test('agrees with the home card for every shared status', () {
      final now = departure.subtract(const Duration(minutes: 10));

      final pairs = {
        TripExecutionStatus.scheduled: AssignedTripStatus.scheduled,
        TripExecutionStatus.openForBooking: AssignedTripStatus.openForBooking,
        TripExecutionStatus.boarding: AssignedTripStatus.boarding,
        TripExecutionStatus.inProgress: AssignedTripStatus.inProgress,
        TripExecutionStatus.completed: AssignedTripStatus.completed,
      };

      pairs.forEach((execution, assigned) {
        expect(
          execution.stageAt(departureTime: departure, now: now),
          _trip(departure, assigned).stageAt(now),
          reason:
              'the execution screen and the home card must never disagree '
              'about what the captain may do next',
        );
      });
    });

    test('a cancelled trip is terminal', () {
      final stage = TripExecutionStatus.cancelled.stageAt(
        departureTime: departure,
        now: departure,
      );

      expect(stage, CaptainTripStage.cancelled);
      expect(stage.isTerminal, isTrue);
      expect(stage.isLive, isFalse);
    });
  });

  group('stage predicates gate the in-trip tools', () {
    test('only boarding and underway count as live', () {
      expect(CaptainTripStage.boarding.isLive, isTrue);
      expect(CaptainTripStage.underway.isLive, isTrue);

      for (final stage in const [
        CaptainTripStage.awaitingRelease,
        CaptainTripStage.awaitingWindow,
        CaptainTripStage.readyToBoard,
        CaptainTripStage.finished,
        CaptainTripStage.cancelled,
      ]) {
        expect(stage.isLive, isFalse, reason: '$stage must not read as live');
      }
    });

    test('readyToBoard is not "waiting" — the captain can act on it', () {
      expect(CaptainTripStage.awaitingRelease.isWaiting, isTrue);
      expect(CaptainTripStage.awaitingWindow.isWaiting, isTrue);
      expect(CaptainTripStage.readyToBoard.isWaiting, isFalse);
    });
  });
}

AssignedTrip _trip(DateTime departure, AssignedTripStatus status) {
  return AssignedTrip(
    id: 'trip-1',
    route: 'القاهرة - الإسكندرية',
    vehicleNumber: 'BUS-1',
    plateNumber: 'أ ب ج 123',
    departureTime: departure,
    expectedArrivalTime: departure.add(const Duration(hours: 3)),
    stops: const [],
    passengerCount: 20,
    boardedCount: 0,
    status: status,
  );
}
