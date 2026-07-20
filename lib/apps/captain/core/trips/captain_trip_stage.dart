/// Where a trip stands from the captain's point of view — the single
/// vocabulary the home screen and the execution screen both speak.
///
/// The backend lifecycle (`operation_trips.status`) has two distinct
/// pre-departure states that the captain app used to collapse into one:
///
/// * `scheduled`        — ops created the trip but has **not** published it.
///                        Clients cannot see or book it yet.
/// * `open_for_booking` — ops published it; clients are booking seats.
///
/// Collapsing them meant a trip that operations had not released yet still
/// offered "بدء الرحلة", letting a captain start a trip nobody could book.
/// Splitting them is what makes the dashboard the gate for release, and the
/// clock the gate for boarding.
library;

/// How early before departure a captain may start boarding.
///
/// Boarding is a physical act at the stop, so it opens on the clock rather
/// than on a dashboard action: ops publishes the trip once, and the captain's
/// button arms itself when the departure is actually near.
const Duration kCaptainBoardingWindow = Duration(minutes: 30);

enum CaptainTripStage {
  /// Assigned to the captain, but operations has not opened booking yet.
  /// Nothing to do but wait — the live watch flips this by itself when the
  /// dashboard publishes the trip.
  awaitingRelease,

  /// Open for booking, but departure is still further out than
  /// [kCaptainBoardingWindow]. Passengers are booking; boarding hasn't earned
  /// its turn.
  awaitingWindow,

  /// Open for booking and inside the boarding window — the captain may start
  /// picking passengers up.
  readyToBoard,

  /// Passengers are boarding.
  boarding,

  /// The trip has departed.
  underway,

  /// Terminal.
  finished,
  cancelled,
}

extension CaptainTripStageX on CaptainTripStage {
  /// The captain is physically running this trip: boarding at the stop, or
  /// driving it. The operational tools (location sharing, the manifest as a
  /// boarding door, SOS) only make sense from here on — offering them on a
  /// trip that hasn't been released yet is noise the captain has to filter.
  bool get isLive =>
      this == CaptainTripStage.boarding || this == CaptainTripStage.underway;

  /// Boarding has not started and cannot be started yet — either operations
  /// hasn't released the trip, or it is too early.
  bool get isWaiting =>
      this == CaptainTripStage.awaitingRelease ||
      this == CaptainTripStage.awaitingWindow;

  bool get isTerminal =>
      this == CaptainTripStage.finished || this == CaptainTripStage.cancelled;
}

/// Splits a published (`open_for_booking`) trip into "too early" versus
/// "board now" against the clock.
CaptainTripStage resolvePublishedStage({
  required DateTime departureTime,
  required DateTime now,
}) {
  final boardingOpensAt = departureTime.subtract(kCaptainBoardingWindow);
  return now.isBefore(boardingOpensAt)
      ? CaptainTripStage.awaitingWindow
      : CaptainTripStage.readyToBoard;
}

/// When the captain may start boarding [departureTime].
DateTime boardingOpensAt(DateTime departureTime) =>
    departureTime.subtract(kCaptainBoardingWindow);
