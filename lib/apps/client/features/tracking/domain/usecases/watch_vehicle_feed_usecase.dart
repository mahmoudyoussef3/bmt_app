import 'dart:async';

import '../entities/tracking_trip.dart';
import '../repositories/tracking_repository.dart';

/// Live vehicle positions and link health for one trip.
///
/// Whether a fix arrived over a socket or a catch-up poll is a data-layer
/// concern; what reaches the domain is "a position was reported" and "the link
/// is/is not healthy", which is all the Bloc above ever needs to know.
class WatchVehicleFeedUseCase {
  const WatchVehicleFeedUseCase(this._repository);

  final TrackingRepository _repository;

  Stream<VehicleFeedEvent> call(String tripId) {
    return _repository.watchVehicleFeed(tripId);
  }
}
