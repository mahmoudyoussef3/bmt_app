class DailyBookingData {
  const DailyBookingData({
    required this.pickupPoints,
    required this.destinations,
    required this.arrivalTimes,
    required this.vehicles,
  });

  final List<String> pickupPoints;
  final List<String> destinations;
  final List<String> arrivalTimes;
  final List<DailyBookingVehicle> vehicles;
}

class DailyBookingVehicle {
  const DailyBookingVehicle({
    required this.id,
    required this.driver,
    required this.time,
    required this.seatsLeft,
    required this.occupancy,
  });

  final String id;
  final String driver;
  final String time;
  final int seatsLeft;
  final double occupancy;
}
