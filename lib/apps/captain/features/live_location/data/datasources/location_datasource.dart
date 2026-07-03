import '../models/location_sharing_model.dart';

abstract class LocationDatasource {
  Future<LocationUpdateModel> sendLocation(String tripId);
}
