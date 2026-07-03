import '../entities/location_sharing_state.dart';

abstract class LocationRepository {
  Future<LocationUpdateData> sendLocation(String tripId);
}
