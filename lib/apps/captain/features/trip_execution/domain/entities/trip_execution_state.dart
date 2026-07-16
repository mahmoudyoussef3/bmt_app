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

/// The captain's last one-shot location send for this trip (see
/// `live_location` — continuous/background tracking is not used). Never
/// treat [recordedAt] as current; the GPS status card shows its age
/// explicitly so a captain who hasn't sent a fresh fix in a while sees that,
/// rather than a number that quietly goes stale.
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
