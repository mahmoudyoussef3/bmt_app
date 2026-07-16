enum TripExecutionStatus {
  scheduled,
  boarding,
  inProgress,
  completed,
  cancelled,
}

class TripExecutionStateData {
  const TripExecutionStateData({required this.tripId, required this.status});

  final String tripId;
  final TripExecutionStatus status;
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
  });

  final TripExecutionStatus status;
  final int passengerCount;
  final int boardedCount;
  final int arrivedStationsCount;

  TripExecutionSnapshot copyWith({TripExecutionStatus? status}) {
    return TripExecutionSnapshot(
      status: status ?? this.status,
      passengerCount: passengerCount,
      boardedCount: boardedCount,
      arrivedStationsCount: arrivedStationsCount,
    );
  }
}
