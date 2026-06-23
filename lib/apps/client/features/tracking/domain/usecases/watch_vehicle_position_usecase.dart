import 'dart:async';

import '../entities/tracking_trip.dart';
import '../repositories/tracking_repository.dart';

class WatchVehiclePositionUseCase {
  const WatchVehiclePositionUseCase(this._repository);

  final TrackingRepository _repository;

  Stream<TrackingPoint> call(String tripId) {
    return _repository.watchVehiclePosition(tripId);
  }
}
