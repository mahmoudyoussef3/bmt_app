class TripHistoryItem {
  const TripHistoryItem({
    required this.id,
    required this.route,
    required this.tripDate,
    required this.departureTime,
    required this.arrivalTime,
    required this.passengerCount,
    required this.boardedCount,
    required this.vehicleNumber,
    required this.plateNumber,
  });

  final String id;
  final String route;
  final DateTime tripDate;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final int passengerCount;
  final int boardedCount;
  final String vehicleNumber;
  final String plateNumber;

  Duration get duration => arrivalTime.difference(departureTime);
  double get boardingRate => passengerCount == 0 ? 0 : boardedCount / passengerCount;
}
