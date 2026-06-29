import '../../domain/entities/location_sharing_state.dart';

class LocationSharingModel {
  const LocationSharingModel({required this.tripId, required this.enabled});

  final String tripId;
  final bool enabled;

  LocationSharingStateData toEntity() {
    return LocationSharingStateData(tripId: tripId, enabled: enabled);
  }
}
