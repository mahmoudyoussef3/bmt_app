import 'package:bmt_app/apps/captain/core/trips/captain_trip_stage.dart';

enum TripExecutionStatus {
  scheduled,
  openForBooking,
  boarding,
  inProgress,
  completed,
  cancelled,
}

extension TripExecutionStatusX on TripExecutionStatus {
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
