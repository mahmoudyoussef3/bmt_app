import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/core/tracking/progress/route_stop.dart';
import 'package:bmt_app/core/tracking/progress/station_board.dart';
import 'package:bmt_app/core/tracking/progress/station_overlay.dart';
import 'package:bmt_app/core/tracking/progress/stop_progress.dart';

/// The overlay decides which of two disagreeing sources the rider is shown.
/// The rule is: the captain's record of what happened beats GPS inference about
/// what probably happened, and a live ETA beats a projected one — but only for a
/// rider still allowed to have live positions.
void main() {
  final now = DateTime(2026, 8, 11, 8, 40);

  test('a station the captain marked departed reads departed, whatever the '
      'engine inferred from position', () {
    final merged = overlayStationBoard(
      inferred: [
        _inferred('A', StopVisitStatus.next, eta: now.add(_min(5))),
        _inferred('B', StopVisitStatus.upcoming),
      ],
      board: StationBoard([
        _station(1, 'A', arrived: now.subtract(_min(20)), departed: now.subtract(_min(15))),
        _station(2, 'B'),
      ]),
      now: now,
    );

    expect(merged.first.status, StopVisitStatus.departed);
    expect(
      merged.first.eta,
      isNull,
      reason: 'a stop the bus left twenty minutes ago has no arrival estimate',
    );
    expect(merged.first.etaConfidence, EtaConfidence.none);
  });

  test('a station the engine thinks was passed but the captain has not left '
      'reverts to ahead — the captain was there, the inference was not', () {
    final merged = overlayStationBoard(
      inferred: [_inferred('A', StopVisitStatus.departed)],
      board: StationBoard([_station(1, 'A')]),
      now: now,
    );

    expect(merged.single.status, StopVisitStatus.next);
  });

  test('a station the captain is standing at reads arrived', () {
    final merged = overlayStationBoard(
      inferred: [_inferred('A', StopVisitStatus.upcoming)],
      board: StationBoard([_station(1, 'A', arrived: now.subtract(_min(2)))]),
      now: now,
    );

    expect(merged.single.status, StopVisitStatus.arrived);
  });

  test('a rider who can still track keeps the sharper live ETA', () {
    final live = now.add(_min(4));
    final merged = overlayStationBoard(
      inferred: [
        _inferred(
          'A',
          StopVisitStatus.next,
          eta: live,
          confidence: EtaConfidence.live,
        ),
      ],
      board: StationBoard([
        _station(1, 'A', expectedArrival: now.add(_min(12))),
      ]),
      now: now,
      preferLiveEta: true,
    );

    expect(merged.single.eta, live);
    expect(merged.single.etaConfidence, EtaConfidence.live);
  });

  test('a rider who has boarded — and so has no positions — gets the board\'s '
      'projection, honestly labelled', () {
    final merged = overlayStationBoard(
      inferred: [
        _inferred(
          'A',
          StopVisitStatus.next,
          eta: now.add(_min(4)),
          confidence: EtaConfidence.live,
        ),
      ],
      board: StationBoard([
        _station(1, 'A', expectedArrival: now.add(_min(12))),
      ]),
      now: now,
      preferLiveEta: false,
    );

    expect(merged.single.eta, now.add(_min(12)));
    expect(merged.single.etaConfidence, EtaConfidence.scheduled);
  });

  test('a stop with no matching board row is left exactly as inferred', () {
    final eta = now.add(_min(9));
    final merged = overlayStationBoard(
      inferred: [
        _inferred('A', StopVisitStatus.next, eta: eta, confidence: EtaConfidence.live),
        _inferred('Z', StopVisitStatus.upcoming),
      ],
      board: StationBoard([_station(1, 'A')]),
      now: now,
    );

    expect(merged[1].status, StopVisitStatus.upcoming);
    expect(merged[0].eta, eta);
  });

  test('an empty board changes nothing', () {
    final inferred = [_inferred('A', StopVisitStatus.next)];

    expect(
      overlayStationBoard(
        inferred: inferred,
        board: const StationBoard.empty(),
        now: now,
      ),
      same(inferred),
    );
  });

  test('an empty stop list changes nothing', () {
    expect(
      overlayStationBoard(
        inferred: const [],
        board: StationBoard([_station(1, 'A')]),
        now: now,
      ),
      isEmpty,
    );
  });

  test('a re-sequenced board still pairs stops with the right station', () {
    // The trip's points were reordered after the board was built, so position
    // no longer lines up. Matching falls back to the name rather than pairing a
    // stop with somebody else's station.
    final merged = overlayStationBoard(
      inferred: [
        _inferred('B', StopVisitStatus.upcoming),
        _inferred('A', StopVisitStatus.upcoming),
      ],
      board: StationBoard([
        _station(1, 'A', arrived: now.subtract(_min(30)), departed: now.subtract(_min(28))),
        _station(2, 'B'),
      ]),
      now: now,
    );

    expect(merged[0].stop.name, 'B');
    expect(merged[0].status, isNot(StopVisitStatus.departed));
    expect(merged[1].stop.name, 'A');
    expect(merged[1].status, StopVisitStatus.departed);
  });
}

Duration _min(int minutes) => Duration(minutes: minutes);

StopProgress _inferred(
  String name,
  StopVisitStatus status, {
  DateTime? eta,
  EtaConfidence confidence = EtaConfidence.estimated,
}) {
  return StopProgress(
    stop: RouteStop(name: name, latitude: 30, longitude: 31, order: 0),
    status: status,
    eta: eta,
    etaConfidence: eta == null ? EtaConfidence.none : confidence,
  );
}

TripStation _station(
  int sequence,
  String name, {
  DateTime? arrived,
  DateTime? departed,
  DateTime? expectedArrival,
}) {
  return TripStation(
    id: 'st-$sequence',
    name: name,
    sequence: sequence,
    status: departed != null
        ? TripStationStatus.departed
        : arrived != null
        ? TripStationStatus.waitingForPassengers
        : TripStationStatus.upcoming,
    expectedArrivalAt: expectedArrival,
    actualArrivalAt: arrived,
    actualDepartureAt: departed,
  );
}
