import 'package:bmt_app/core/tracking/vehicle_fix.dart';

import '../entities/location_sharing_state.dart';
import '../repositories/location_repository.dart';

/// Writes one already-validated, already-throttled fix.
class PublishTripLocationUseCase {
  const PublishTripLocationUseCase(this._repository);

  final LocationRepository _repository;

  Future<LocationUpdateData> call(String tripId, VehicleFix fix) {
    return _repository.publishFix(tripId, fix);
  }
}
