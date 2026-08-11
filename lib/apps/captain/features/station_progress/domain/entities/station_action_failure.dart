/// Why the database refused a station transition.
///
/// The refusals are not error handling in the incidental sense — they *are* the
/// feature. A captain who taps "متابعة" one second before the vehicle is due out
/// gets `departureTimeReached`, and the screen has to say so rather than showing
/// a generic failure and leaving them to guess.
enum StationActionFailure {
  /// The caller is not this trip's captain.
  notYourTrip,

  /// The trip is not boarding or in progress.
  tripNotRunning,

  /// The vehicle has not reported arriving anywhere, or this station was already
  /// departed — including by a retry of this very request.
  noCurrentStation,

  /// Every stop has been left already.
  noPendingStation,

  /// Riders are still expected here.
  passengersNotBoarded,

  /// The configured dwell or the published departure time has not passed.
  departureTimeNotReached,

  /// A no-show was submitted without the note `other` requires.
  noShowNoteRequired,

  /// The rider is no longer in a state that can become a no-show.
  passengerNotPending,

  /// Anything else — a dropped connection, a server fault.
  unknown,
}

/// A refused station transition, carrying the detail the message needs.
class StationActionException implements Exception {
  const StationActionException(this.failure, {this.detail});

  final StationActionFailure failure;

  /// The payload the database attached after the colon: a pending-passenger
  /// count, or the "HH:mm" the vehicle becomes free to leave.
  final String? detail;

  /// Riders still expected, when the refusal was a boarding one.
  int? get pendingCount =>
      failure == StationActionFailure.passengersNotBoarded && detail != null
      ? int.tryParse(detail!.trim())
      : null;

  /// The clock time the vehicle may leave, when the refusal was a timing one.
  String? get earliestDeparture =>
      failure == StationActionFailure.departureTimeNotReached ? detail : null;

  @override
  String toString() => 'StationActionException(${failure.name}, $detail)';
}

/// Maps a Postgres error message onto the refusal it represents.
///
/// The RPCs raise `code:detail`, so the code is matched as a prefix and the
/// detail kept. Anything unrecognised stays [StationActionFailure.unknown]
/// rather than being guessed at — a refusal the app does not understand must
/// not be rendered as one it does.
StationActionException stationFailureFrom(Object error) {
  final message = error.toString();

  for (final entry in _codes.entries) {
    final index = message.indexOf(entry.key);
    if (index < 0) continue;
    return StationActionException(
      entry.value,
      detail: _detailAfter(message, index + entry.key.length),
    );
  }
  return const StationActionException(StationActionFailure.unknown);
}

const _codes = <String, StationActionFailure>{
  'passengers_not_boarded': StationActionFailure.passengersNotBoarded,
  'departure_time_not_reached': StationActionFailure.departureTimeNotReached,
  'no_current_station': StationActionFailure.noCurrentStation,
  'no_pending_station': StationActionFailure.noPendingStation,
  'no_show_note_required': StationActionFailure.noShowNoteRequired,
  'passenger_not_pending': StationActionFailure.passengerNotPending,
  'trip_not_running': StationActionFailure.tripNotRunning,
  'not_your_trip': StationActionFailure.notYourTrip,
  'not_a_captain': StationActionFailure.notYourTrip,
};

/// The `:detail` suffix, up to whatever punctuation the driver wrapped it in.
String? _detailAfter(String message, int start) {
  if (start >= message.length || message[start] != ':') return null;
  final rest = message.substring(start + 1);
  final end = rest.indexOf(RegExp(r'[",\n]'));
  final detail = (end < 0 ? rest : rest.substring(0, end)).trim();
  return detail.isEmpty ? null : detail;
}
