class LocationUpdateData {
  const LocationUpdateData({
    required this.tripId,
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
  });

  final String tripId;
  final double latitude;
  final double longitude;
  final DateTime recordedAt;
}
