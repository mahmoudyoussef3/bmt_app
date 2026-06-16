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
    required this.capacity,
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
  final int capacity;
  final int availableSeats;
  final String estimatedArrival;
  final String routeDuration;
  final String departureTime;
  final String driverInitials;

  int get occupiedSeats => (capacity - availableSeats).clamp(0, capacity);

  double get occupancyRatio {
    if (capacity <= 0) return 0;
    return occupiedSeats / capacity;
  }
}

enum VehicleSortOption { recommended, priceLow, rating, seats }
