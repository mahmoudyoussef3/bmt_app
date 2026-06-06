enum TripExecutionStatus { scheduled, inProgress, completed }

class TripExecutionStateData {
  const TripExecutionStateData({required this.tripId, required this.status});

  final String tripId;
  final TripExecutionStatus status;
}
