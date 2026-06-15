class VehicleDetailData {
  const VehicleDetailData({
    required this.id, // This will be the trip_id
    required this.name,
    required this.model,
    required this.vehicleType,
    required this.imageLabels,
    required this.hasAirConditioning,
    required this.seatType,
    required this.driverName,
    required this.price,
    required this.availableSeats,
    required this.estimatedArrival,
    required this.routeDuration,
    required this.departureTime,
    this.driverInitials = 'AM',
  });

  final String id;
  final String name;
  final String model;
  final String vehicleType;
  final List<String> imageLabels;
  final bool hasAirConditioning;
  final String seatType;
  final String driverName;
  final String price;
  final int availableSeats;
  final String estimatedArrival;
  final String routeDuration;
  final String departureTime;
  final String driverInitials;
}

enum VehicleSortOption { recommended, priceLow, rating, seats }
