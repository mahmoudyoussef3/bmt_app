import 'package:bmt_app/core/tracking/vehicle_fix.dart';

import '../models/location_sharing_model.dart';

abstract class LocationDatasource {
  /// Acquire a position and publish it. The manual "send my location now"
  /// path, which wants one answer rather than a subscription.
  Future<LocationUpdateModel> sendLocation(String tripId);

  /// Publish a fix the caller already holds.
  ///
  /// The automatic path uses this: the GPS stream acquires, the pipeline
  /// validates and throttles, and only then does anything reach the database.
  /// Writing had to become separable from acquiring before any of that was
  /// possible.
  Future<LocationUpdateModel> publishFix(String tripId, VehicleFix fix);

  /// The device's own position stream, unjudged.
  Stream<VehicleFix> watchDevicePosition();
}
