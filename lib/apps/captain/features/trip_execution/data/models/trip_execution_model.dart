import '../../domain/entities/trip_execution_state.dart';

class TripExecutionModel {
  const TripExecutionModel({required this.tripId, required this.status});

  final String tripId;
  final TripExecutionStatus status;

  TripExecutionStateData toEntity() {
    return TripExecutionStateData(tripId: tripId, status: status);
  }
}
