enum TripExecutionStatus { scheduled, boarding, inProgress, completed, cancelled }

class TripExecutionStateData {
  const TripExecutionStateData({required this.tripId, required this.status});

  final String tripId;
  final TripExecutionStatus status;
}
