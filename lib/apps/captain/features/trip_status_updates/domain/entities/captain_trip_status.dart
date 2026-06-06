enum CaptainTripStatus {
  headingToPickup,
  arrivedPickup,
  boarding,
  departed,
  arrivedDestination,
  completed,
}

class CaptainTripStatusUpdate {
  const CaptainTripStatusUpdate({required this.tripId, required this.status});

  final String tripId;
  final CaptainTripStatus status;
}
