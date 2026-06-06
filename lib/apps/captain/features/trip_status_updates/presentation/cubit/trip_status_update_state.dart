import '../../domain/entities/captain_trip_status.dart';

sealed class TripStatusUpdateState {
  const TripStatusUpdateState();
}

class TripStatusUpdateReady extends TripStatusUpdateState {
  const TripStatusUpdateReady({this.status});

  final CaptainTripStatus? status;
}

class TripStatusUpdateLoading extends TripStatusUpdateState {
  const TripStatusUpdateLoading();
}

class TripStatusUpdateError extends TripStatusUpdateState {
  const TripStatusUpdateError(this.message);

  final String message;
}
