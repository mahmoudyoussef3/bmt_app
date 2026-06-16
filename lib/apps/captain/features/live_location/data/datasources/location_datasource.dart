import '../models/location_sharing_model.dart';

abstract class LocationDatasource {
  Future<LocationSharingModel> startSharing(String tripId);
  Future<LocationSharingModel> stopSharing(String tripId);
}
