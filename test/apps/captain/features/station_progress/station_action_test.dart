import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/captain/features/station_progress/domain/entities/station_action.dart';
import 'package:bmt_app/core/tracking/progress/station_board.dart';

/// "What is the one thing the captain can do right now?" — asked without a
/// widget, a cubit or a network in the way.
void main() {
  final now = DateTime(2026, 8, 11, 8, 40);

  test('driving towards a station: report arriving', () {
    final action = resolveStationAction(
      StationBoard([_station(1, 'محطة بنها')]),
      now,
    );

    expect(action, isA<StationArriveAction>());
    expect((action as StationArriveAction).station.name, 'محطة بنها');
  });

  test('standing at a station with riders outstanding: the gate is shut', () {
    final action = resolveStationAction(
      StationBoard([
        _station(
          1,
          'محطة بنها',
          arrived: now.subtract(const Duration(minutes: 20)),
          expectedDeparture: now.subtract(const Duration(minutes: 10)),
          expected: 3,
          boarded: 2,
          pending: 1,
        ),
      ]),
      now,
    );

    expect(action, isA<StationDepartAction>());
    final depart = action as StationDepartAction;
    expect(depart.isEnabled, isFalse);
    expect(depart.gate.state, StationGateState.waitingForPassengers);
    expect(depart.gate.pendingCount, 1);
  });

  test('standing at a station too early: the gate is still shut', () {
    final action =
        resolveStationAction(
              StationBoard([
                _station(
                  1,
                  'محطة بنها',
                  arrived: now,
                  expectedDeparture: now.add(const Duration(minutes: 5)),
                  expected: 2,
                  boarded: 2,
                ),
              ]),
              now,
            )
            as StationDepartAction;

    expect(action.isEnabled, isFalse);
    expect(action.gate.state, StationGateState.waitingForDepartureTime);
  });

  test('both conditions met: continue', () {
    final action =
        resolveStationAction(
              StationBoard([
                _station(
                  1,
                  'محطة بنها',
                  arrived: now.subtract(const Duration(minutes: 20)),
                  expectedDeparture: now.subtract(const Duration(minutes: 10)),
                  expected: 2,
                  boarded: 2,
                ),
              ]),
              now,
            )
            as StationDepartAction;

    expect(action.isEnabled, isTrue);
  });

  test('every station left behind: end the trip', () {
    final action = resolveStationAction(
      StationBoard([
        _station(
          1,
          'A',
          arrived: now.subtract(const Duration(minutes: 40)),
          departed: now.subtract(const Duration(minutes: 35)),
        ),
        _station(
          2,
          'B',
          arrived: now.subtract(const Duration(minutes: 10)),
          departed: now.subtract(const Duration(minutes: 5)),
        ),
      ]),
      now,
    );

    expect(action, isA<StationFinishAction>());
  });

  test('a trip with no stations falls back rather than trapping the captain '
      'behind a gate that can never open', () {
    expect(
      resolveStationAction(const StationBoard.empty(), now),
      isA<StationBoardUnavailable>(),
    );
  });
}

TripStation _station(
  int sequence,
  String name, {
  DateTime? arrived,
  DateTime? departed,
  DateTime? expectedDeparture,
  int expected = 0,
  int boarded = 0,
  int pending = 0,
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
    expectedDepartureAt: expectedDeparture,
    actualArrivalAt: arrived,
    actualDepartureAt: departed,
    expectedBoardings: expected,
    boardedCount: boarded,
    pendingCount: pending,
  );
}
