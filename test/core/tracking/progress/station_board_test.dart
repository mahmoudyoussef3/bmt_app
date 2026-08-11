import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/core/tracking/progress/station_board.dart';
import 'package:bmt_app/core/tracking/progress/stop_progress.dart';

/// The departure gate and the station lifecycle, tested as the pure functions
/// they are. Every case here has a mirror in `captain_depart_station`; this side
/// decides whether the button is live, that side decides whether the vehicle
/// moves, and they have to agree.
void main() {
  final now = DateTime(2026, 8, 11, 8, 40);

  group('station lifecycle', () {
    test('a station is current between arriving and departing', () {
      final station = _station(actualArrival: now.subtract(_min(2)));

      expect(station.hasArrived, isTrue);
      expect(station.hasDeparted, isFalse);
      expect(station.isCurrent, isTrue);
    });

    test('a departed station is no longer current', () {
      final station = _station(
        actualArrival: now.subtract(_min(20)),
        actualDeparture: now.subtract(_min(15)),
        status: TripStationStatus.departed,
      );

      expect(station.isCurrent, isFalse);
      expect(station.hasDeparted, isTrue);
    });

    test('statuses map from the database vocabulary, unknown falls to upcoming',
        () {
      expect(tripStationStatusFrom('arriving'), TripStationStatus.arriving);
      expect(
        tripStationStatusFrom('waiting_for_passengers'),
        TripStationStatus.waitingForPassengers,
      );
      expect(tripStationStatusFrom('departed'), TripStationStatus.departed);
      expect(tripStationStatusFrom(null), TripStationStatus.upcoming);
      expect(tripStationStatusFrom('something_new'), TripStationStatus.upcoming);
    });
  });

  group('earliest departure — the two clocks', () {
    test('a late arrival still owes the configured dwell', () {
      // Due out at 08:30, actually arrived 08:39 with a 5-minute dwell: the
      // published time has passed, so the dwell binds.
      final station = _station(
        actualArrival: DateTime(2026, 8, 11, 8, 39),
        expectedDeparture: DateTime(2026, 8, 11, 8, 30),
        minDwell: _min(5),
      );

      expect(station.earliestDeparture, DateTime(2026, 8, 11, 8, 44));
    });

    test('an early arrival still waits for the published time', () {
      // Arrived 08:10 with a 5-minute dwell but not due out until 08:30 — the
      // riders were told 08:30 and are not there yet.
      final station = _station(
        actualArrival: DateTime(2026, 8, 11, 8, 10),
        expectedDeparture: DateTime(2026, 8, 11, 8, 30),
        minDwell: _min(5),
      );

      expect(station.earliestDeparture, DateTime(2026, 8, 11, 8, 30));
    });

    test('an untimed stop is gated by the dwell alone', () {
      final station = _station(
        actualArrival: DateTime(2026, 8, 11, 8, 39),
        minDwell: _min(3),
      );

      expect(station.earliestDeparture, DateTime(2026, 8, 11, 8, 42));
    });

    test('a stop with no dwell and no plan is not time-gated at all', () {
      final station = _station(actualArrival: DateTime(2026, 8, 11, 8, 39));
      expect(station.earliestDeparture, DateTime(2026, 8, 11, 8, 39));
    });
  });

  group('departure gate', () {
    test('between stations there is nothing to leave', () {
      final board = StationBoard([_station(sequence: 1), _station(sequence: 2)]);

      expect(board.gateAt(now).state, StationGateState.notAtStation);
      expect(board.gateAt(now).canDepart, isFalse);
    });

    test('pending riders hold the vehicle regardless of the clock', () {
      final board = StationBoard([
        _station(
          actualArrival: now.subtract(_min(30)),
          expectedDeparture: now.subtract(_min(20)),
          expected: 5,
          boarded: 4,
          pending: 1,
        ),
      ]);

      final gate = board.gateAt(now);
      expect(gate.state, StationGateState.waitingForPassengers);
      expect(gate.pendingCount, 1);
      expect(gate.canDepart, isFalse);
    });

    test('everyone aboard but not yet due out waits on the clock', () {
      final board = StationBoard([
        _station(
          actualArrival: now.subtract(_min(1)),
          expectedDeparture: now.add(_min(5)),
          expected: 3,
          boarded: 3,
        ),
      ]);

      final gate = board.gateAt(now);
      expect(gate.state, StationGateState.waitingForDepartureTime);
      expect(gate.earliestDeparture, now.add(_min(5)));
      expect(gate.countdown(now), _min(5));
      expect(gate.canDepart, isFalse);
    });

    test('both conditions met is the only way the gate opens', () {
      final board = StationBoard([
        _station(
          actualArrival: now.subtract(_min(20)),
          expectedDeparture: now.subtract(_min(10)),
          expected: 3,
          boarded: 3,
        ),
      ]);

      final gate = board.gateAt(now);
      expect(gate.state, StationGateState.ready);
      expect(gate.canDepart, isTrue);
      expect(gate.countdown(now), isNull);
    });

    test('a no-show counts as resolved, so it opens the gate', () {
      final board = StationBoard([
        _station(
          actualArrival: now.subtract(_min(20)),
          expectedDeparture: now.subtract(_min(10)),
          expected: 3,
          boarded: 2,
          pending: 0,
          noShow: 1,
        ),
      ]);

      expect(board.gateAt(now).canDepart, isTrue);
    });

    test('a stop nobody boards at is never held by boarding', () {
      final board = StationBoard([
        _station(
          actualArrival: now.subtract(_min(20)),
          expectedDeparture: now.subtract(_min(10)),
        ),
      ]);

      expect(board.gateAt(now).canDepart, isTrue);
    });
  });

  group('navigation across the board', () {
    test('current, next and focus pick out the right stations', () {
      final board = StationBoard([
        _station(
          sequence: 1,
          actualArrival: now.subtract(_min(40)),
          actualDeparture: now.subtract(_min(35)),
          status: TripStationStatus.departed,
        ),
        _station(sequence: 2, actualArrival: now.subtract(_min(2)), name: 'B'),
        _station(sequence: 3, name: 'C'),
      ]);

      expect(board.currentStation?.name, 'B');
      expect(board.nextStation?.name, 'C');
      expect(board.focusStation?.name, 'B');
      expect(board.departedCount, 1);
      expect(board.remainingCount, 2);
    });

    test('between stations, focus is the one being driven towards', () {
      final board = StationBoard([
        _station(
          sequence: 1,
          actualArrival: now.subtract(_min(40)),
          actualDeparture: now.subtract(_min(35)),
          status: TripStationStatus.departed,
        ),
        _station(sequence: 2, name: 'B'),
      ]);

      expect(board.currentStation, isNull);
      expect(board.focusStation?.name, 'B');
    });

    test('a pickup resolves by route point id first, name second', () {
      final board = StationBoard([
        _station(sequence: 1, name: 'محطة بنها', routePointId: 'rp-1'),
        _station(sequence: 2, name: 'محطة بنها', routePointId: 'rp-2'),
      ]);

      expect(
        board.stationForPickup(routePointId: 'rp-2', name: 'محطة بنها')?.sequence,
        2,
        reason: 'the id disambiguates two stations sharing a name',
      );
      expect(board.stationForPickup(name: 'محطة بنها')?.sequence, 1);
      expect(board.stationForPickup(name: 'محطة أخرى'), isNull);
      expect(board.stationForPickup(), isNull);
    });
  });

  group('delay and ETA projection', () {
    test('with no observations at all, ETAs are the published schedule', () {
      final board = StationBoard([
        _station(
          sequence: 1,
          expectedArrival: now.add(_min(10)),
          expectedDeparture: now.add(_min(13)),
        ),
        _station(sequence: 2, expectedArrival: now.add(_min(25))),
      ]);

      expect(board.hasObservedProgress, isFalse);
      final etas = board.etas(now);
      expect(etas.first.at, now.add(_min(10)));
      expect(etas.first.confidence, EtaConfidence.scheduled);
    });

    test('a late arrival pushes every remaining station by the same delay', () {
      // Station 1 was due at 08:30 and arrived at 08:38 — eight minutes down.
      final board = StationBoard([
        _station(
          sequence: 1,
          expectedArrival: DateTime(2026, 8, 11, 8, 30),
          expectedDeparture: DateTime(2026, 8, 11, 8, 33),
          actualArrival: DateTime(2026, 8, 11, 8, 38),
        ),
        _station(sequence: 2, expectedArrival: DateTime(2026, 8, 11, 9, 0)),
        _station(sequence: 3, expectedArrival: DateTime(2026, 8, 11, 9, 30)),
      ]);

      final at = DateTime(2026, 8, 11, 8, 40);
      expect(board.delayAt(at), _min(8));

      final etas = board.etas(at);
      expect(etas[1].at, DateTime(2026, 8, 11, 9, 8));
      expect(etas[2].at, DateTime(2026, 8, 11, 9, 38));
      expect(etas[1].confidence, EtaConfidence.estimated);
    });

    test('a vehicle held past its projected departure slips further', () {
      // Due out at 08:33, arrived on time, and it is now 08:50 — still standing
      // there. The delay is the overrun, not zero.
      final board = StationBoard([
        _station(
          sequence: 1,
          expectedArrival: DateTime(2026, 8, 11, 8, 30),
          expectedDeparture: DateTime(2026, 8, 11, 8, 33),
          actualArrival: DateTime(2026, 8, 11, 8, 30),
        ),
        _station(sequence: 2, expectedArrival: DateTime(2026, 8, 11, 9, 0)),
      ]);

      final at = DateTime(2026, 8, 11, 8, 50);
      expect(board.delayAt(at), _min(17));
      expect(board.etas(at)[1].at, DateTime(2026, 8, 11, 9, 17));
    });

    test('a departed station has no ETA — it has a time it happened', () {
      final board = StationBoard([
        _station(
          sequence: 1,
          expectedArrival: DateTime(2026, 8, 11, 8, 30),
          actualArrival: DateTime(2026, 8, 11, 8, 30),
          actualDeparture: DateTime(2026, 8, 11, 8, 33),
          status: TripStationStatus.departed,
        ),
      ]);

      final eta = board.etas(now).single;
      expect(eta.at, isNull);
      expect(eta.confidence, EtaConfidence.none);
    });

    test('an untimed stop gets no invented estimate', () {
      final board = StationBoard([_station(sequence: 1)]);

      final eta = board.etas(now).single;
      expect(eta.at, isNull);
      expect(eta.confidence, EtaConfidence.none);
    });

    test('the station the vehicle is standing at reads its real arrival, not a '
        'projection into the future', () {
      final board = StationBoard([
        _station(
          sequence: 1,
          expectedArrival: DateTime(2026, 8, 11, 9, 0),
          actualArrival: DateTime(2026, 8, 11, 8, 55),
        ),
      ]);

      expect(board.etas(now).single.at, DateTime(2026, 8, 11, 8, 55));
    });

    test('an empty board answers everything without throwing', () {
      const board = StationBoard.empty();

      expect(board.isEmpty, isTrue);
      expect(board.currentStation, isNull);
      expect(board.focusStation, isNull);
      expect(board.etas(now), isEmpty);
      expect(board.gateAt(now).state, StationGateState.notAtStation);
      expect(board.delayAt(now), Duration.zero);
    });
  });
}

Duration _min(int minutes) => Duration(minutes: minutes);

TripStation _station({
  int sequence = 1,
  String name = 'A',
  String? routePointId,
  DateTime? expectedArrival,
  DateTime? expectedDeparture,
  DateTime? actualArrival,
  DateTime? actualDeparture,
  Duration minDwell = Duration.zero,
  TripStationStatus status = TripStationStatus.upcoming,
  int expected = 0,
  int boarded = 0,
  int pending = 0,
  int noShow = 0,
}) {
  return TripStation(
    id: 'st-$sequence-$name',
    name: name,
    sequence: sequence,
    status: status,
    routePointId: routePointId,
    expectedArrivalAt: expectedArrival,
    expectedDepartureAt: expectedDeparture,
    minDwell: minDwell,
    actualArrivalAt: actualArrival,
    actualDepartureAt: actualDeparture,
    expectedBoardings: expected,
    boardedCount: boarded,
    pendingCount: pending,
    noShowCount: noShow,
  );
}
