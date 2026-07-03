import '../../domain/entities/location_sharing_state.dart';

class LocationUpdateModel {
  const LocationUpdateModel({
    required this.tripId,
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
  });

  final String tripId;
  final double latitude;
  final double longitude;
  final DateTime recordedAt;

  LocationUpdateData toEntity() {
    return LocationUpdateData(
      tripId: tripId,
      latitude: latitude,
      longitude: longitude,
      recordedAt: recordedAt,
    );
  }
}
