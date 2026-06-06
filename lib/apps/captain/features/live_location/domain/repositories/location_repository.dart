import '../entities/location_sharing_state.dart';

abstract class LocationRepository {
  Future<LocationSharingStateData> startSharing(String tripId);
  Future<LocationSharingStateData> stopSharing(String tripId);
}
