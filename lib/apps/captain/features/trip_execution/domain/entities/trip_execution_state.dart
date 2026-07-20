import 'package:bmt_app/apps/captain/core/trips/captain_trip_stage.dart';

/// Mirrors `operation_trips.status`.
///
/// [scheduled] (ops draft, invisible to clients) and [openForBooking]
/// (published, clients are booking) are separate states in the backend's
/// transition machine — `scheduled → open_for_booking → boarding` — and the
/// captain can only act on the second. Collapsing them let the execution
/// screen offer "بدء صعود الركاب" on a trip whose next legal transition was
/// operations publishing it, so the tap could only ever fail.
enum TripExecutionStatus {
  scheduled,
  openForBooking,
  boarding,
  inProgress,
  completed,
  cancelled,
}

extension TripExecutionStatusX on TripExecutionStatus {
  /// Where the captain stands, combining this status with the departure clock.
  CaptainTripStage stageAt({
    required DateTime departureTime,
    required DateTime now,
  }) {
    return switch (this) {
      TripExecutionStatus.scheduled => CaptainTripStage.awaitingRelease,
      TripExecutionStatus.openForBooking => resolvePublishedStage(
        departureTime: departureTime,
        now: now,
      ),
      TripExecutionStatus.boarding => CaptainTripStage.boarding,
      TripExecutionStatus.inProgress => CaptainTripStage.underway,
      TripExecutionStatus.completed => CaptainTripStage.finished,
      TripExecutionStatus.cancelled => CaptainTripStage.cancelled,
    };
  }
}

class TripExecutionStateData {
  const TripExecutionStateData({required this.tripId, required this.status});

  final String tripId;
  final TripExecutionStatus status;
}

/// The captain's most recently stored position for this trip.
///
/// A running trip reports automatically every minute (see
/// `TripLocationAutoShare`), but never treat [recordedAt] as current: the
/// send can fail on a dead signal or a denied permission. The GPS status card
/// shows its age explicitly so a fix that stopped updating is visible as
/// exactly that, rather than a number that quietly goes stale.
class TripLastLocationFix {
  const TripLastLocationFix({
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
  });

  final double latitude;
  final double longitude;
  final DateTime recordedAt;
}

/// Live snapshot of a trip's execution progress.
///
/// Watched continuously for the lifetime of the execution screen, so the
/// counts move as passengers actually check in and stations are reported
/// arrived — never frozen at whatever they were when the screen was opened.
class TripExecutionSnapshot {
  const TripExecutionSnapshot({
    required this.status,
    required this.passengerCount,
    required this.boardedCount,
    required this.arrivedStationsCount,
    this.lastLocation,
  });

  final TripExecutionStatus status;
  final int passengerCount;
  final int boardedCount;
  final int arrivedStationsCount;
  final TripLastLocationFix? lastLocation;

  TripExecutionSnapshot copyWith({TripExecutionStatus? status}) {
    return TripExecutionSnapshot(
      status: status ?? this.status,
      passengerCount: passengerCount,
      boardedCount: boardedCount,
      arrivedStationsCount: arrivedStationsCount,
      lastLocation: lastLocation,
    );
  }
}
