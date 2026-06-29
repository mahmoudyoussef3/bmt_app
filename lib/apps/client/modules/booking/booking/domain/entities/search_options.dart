class TripSearchOptions {
  const TripSearchOptions({
    required this.pickupPoints,
    required this.destinations,
    required this.departureTimes,
  });

  final List<String> pickupPoints;
  final List<String> destinations;
  final List<String> departureTimes;

  bool get hasPickups => pickupPoints.isNotEmpty;
  bool get hasDestinations => destinations.isNotEmpty;
  bool get hasTimes => departureTimes.isNotEmpty;
}
