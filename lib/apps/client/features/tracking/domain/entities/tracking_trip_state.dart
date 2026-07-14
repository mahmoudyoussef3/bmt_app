/// Where the trip is, from the rider's point of view.
///
/// Derived on the server side of the data layer from the trip's own status
/// plus the captain's reported events — never from anything the UI can set.
enum TrackingTripState {
  notStarted,
  driverOnWay,
  boarding,
  inProgress,
  completed;

  bool get isActive => this != TrackingTripState.notStarted;

  bool get isFinished => this == TrackingTripState.completed;
}
