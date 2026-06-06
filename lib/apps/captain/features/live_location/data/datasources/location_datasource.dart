import '../models/location_sharing_model.dart';

class LocationDataSource {
  const LocationDataSource();

  Future<LocationSharingModel> startSharing(String tripId) async {
    return LocationSharingModel(tripId: tripId, enabled: true);
  }

  Future<LocationSharingModel> stopSharing(String tripId) async {
    return LocationSharingModel(tripId: tripId, enabled: false);
  }
}
