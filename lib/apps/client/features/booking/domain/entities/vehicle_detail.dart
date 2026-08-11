class VehicleDetailData {
  const VehicleDetailData({
    required this.id, 
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
    this.driverRating = 0,
    this.driverRatingCount = 0,
    this.vehicleRating = 0,
    this.vehicleRatingCount = 0,
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

  /// Public averages, aggregated from passenger reviews of past trips. A count
  /// of zero means nobody has reviewed this captain / vehicle yet — which is
  /// not the same as being rated badly, and must not be rendered as 0 stars.
  final double driverRating;
  final int driverRatingCount;
  final double vehicleRating;
  final int vehicleRatingCount;

  bool get hasDriverRating => driverRatingCount > 0 && driverRating > 0;

  bool get hasVehicleRating => vehicleRatingCount > 0 && vehicleRating > 0;

  /// What "sort by rating" ranks on: the captain and the vehicle together are
  /// what the passenger actually experiences on board.
  double get combinedRating {
    final ratings = [
      if (hasDriverRating) driverRating,
      if (hasVehicleRating) vehicleRating,
    ];
    if (ratings.isEmpty) return 0;
    return ratings.reduce((a, b) => a + b) / ratings.length;
  }

  int get occupiedSeats => (capacity - availableSeats).clamp(0, capacity);

  double get occupancyRatio {
    if (capacity <= 0) return 0;
    return occupiedSeats / capacity;
  }
}

enum VehicleSortOption { recommended, priceLow, rating, seats }
