import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/captain/features/station_progress/domain/entities/station_action_failure.dart';
import 'package:bmt_app/apps/captain/features/station_progress/presentation/formatters/station_labels.dart';

/// The two interesting refusals are not errors — they are the departure rule
/// doing its job — so they have to survive the trip from Postgres to the button
/// with their detail intact. "متبقي راكب واحد" is a different message from
/// "يمكنك المغادرة بعد 08:45", and a generic failure would be neither.
void main() {
  group('parsing the server refusal', () {
    test('carries the pending-passenger count through', () {
      final failure = stationFailureFrom(
        'PostgrestException(message: passengers_not_boarded:2, code: P0001)',
      );

      expect(failure.failure, StationActionFailure.passengersNotBoarded);
      expect(failure.pendingCount, 2);
      expect(StationLabels.failure(failure), 'متبقي راكبان');
    });

    test('carries the earliest departure clock through', () {
      final failure = stationFailureFrom('departure_time_not_reached:08:45');

      expect(failure.failure, StationActionFailure.departureTimeNotReached);
      expect(failure.earliestDeparture, '08:45');
      expect(StationLabels.failure(failure), 'يمكنك المغادرة بعد 08:45');
    });

    test('recognises the duplicate-progression refusal', () {
      expect(
        stationFailureFrom('no_current_station').failure,
        StationActionFailure.noCurrentStation,
      );
    });

    test('recognises every authorisation refusal as "not yours"', () {
      expect(
        stationFailureFrom('not_your_trip').failure,
        StationActionFailure.notYourTrip,
      );
      expect(
        stationFailureFrom('not_a_captain').failure,
        StationActionFailure.notYourTrip,
      );
    });

    test('recognises the no-show guards', () {
      expect(
        stationFailureFrom('no_show_note_required').failure,
        StationActionFailure.noShowNoteRequired,
      );
      expect(
        stationFailureFrom('passenger_not_pending:no_show').failure,
        StationActionFailure.passengerNotPending,
      );
    });

    test('an unrecognised refusal stays unknown rather than being guessed at', () {
      final failure = stationFailureFrom('some_future_rule_we_do_not_know');

      expect(failure.failure, StationActionFailure.unknown);
      expect(failure.pendingCount, isNull);
      expect(failure.earliestDeparture, isNull);
      expect(StationLabels.failure(failure), isNotEmpty);
    });

    test('a refusal with no detail does not invent one', () {
      final failure = stationFailureFrom('passengers_not_boarded');

      expect(failure.failure, StationActionFailure.passengersNotBoarded);
      expect(failure.pendingCount, isNull);
      expect(
        StationLabels.failure(failure),
        'لا يمكن المغادرة قبل صعود جميع الركاب',
      );
    });
  });

  group('Arabic counting', () {
    test('one, two and many are worded differently', () {
      expect(StationLabels.remainingToBoard(1), 'متبقي راكب واحد');
      expect(StationLabels.remainingToBoard(2), 'متبقي راكبان');
      expect(StationLabels.remainingToBoard(5), 'متبقي 5 ركاب');
    });

    test('passenger and station counts follow the same forms', () {
      expect(StationLabels.passengers(0), 'لا ركاب');
      expect(StationLabels.passengers(1), 'راكب واحد');
      expect(StationLabels.passengers(2), 'راكبان');
      expect(StationLabels.stations(1), 'محطة واحدة');
      expect(StationLabels.stations(2), 'محطتان');
      expect(StationLabels.stations(4), '4 محطات');
    });
  });
}
