import 'package:bmt_app/core/tracking/vehicle_fix.dart';

import '../entities/location_sharing_state.dart';

abstract class LocationRepository {
  /// Acquire a position and publish it in one step.
  Future<LocationUpdateData> sendLocation(String tripId);

  /// Publish a fix the pipeline has already validated and throttled.
  Future<LocationUpdateData> publishFix(String tripId, VehicleFix fix);

  /// The device's raw position stream, before validation or throttling.
  Stream<VehicleFix> watchDevicePosition();
}
