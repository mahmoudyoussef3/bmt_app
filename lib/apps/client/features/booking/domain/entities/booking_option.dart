/// How closely a route matches the user's pickup/destination search.
enum RouteMatchQuality {
  /// Route serves both the requested pickup and destination, in order.
  exact,

  /// Route serves the pickup or destination, but not a perfect pairing.
  partial,

  /// Closest available route; does not directly match the search.
  suggested,
}

class RouteOptionData {
  const RouteOptionData({
    required this.id,
    required this.routeName,
    required this.pickup,
    required this.destination,
    required this.distance,
    required this.duration,
    required this.availableSeats,
    required this.startingPrice,
    required this.priceRange,
    required this.availableTrips,
    this.points = const [],
    this.isFastest = false,
    this.matchQuality = RouteMatchQuality.exact,
  });

  final String id;
  final String routeName;
  final String pickup;
  final String destination;
  final String distance;
  final String duration;
  final int availableSeats;
  final String startingPrice;
  final String priceRange;
  final List<RouteTripOptionData> availableTrips;
  final List<RoutePointData> points;
  final bool isFastest;
  final RouteMatchQuality matchQuality;

  bool get isExactMatch => matchQuality == RouteMatchQuality.exact;
}

class RoutePointData {
  const RoutePointData({
    required this.name,
    required this.order,
    this.id = '',
    this.pickupAllowed = true,
    this.dropoffAllowed = true,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String name;
  final int order;
  final bool pickupAllowed;
  final bool dropoffAllowed;
  final double? latitude;
  final double? longitude;
}

class RouteTripOptionData {
  const RouteTripOptionData({
    required this.id,
    required this.departureTime,
    required this.arrivalTime,
    required this.availableSeats,
    required this.vehicleType,
    required this.price,
    this.tripDate = '',
  });

  final String id;
  final String tripDate;
  final String departureTime;
  final String arrivalTime;
  final int availableSeats;
  final String vehicleType;
  final String price;
}

class PopularRouteListData {
  const PopularRouteListData({
    required this.id,
    required this.routeName,
    required this.dailyTrips,
    required this.averageDuration,
    required this.startingPrice,
    required this.pickup,
    required this.destination,
    required this.distance,
  });

  final String id;
  final String routeName;
  final int dailyTrips;
  final String averageDuration;
  final String startingPrice;
  final String pickup;
  final String destination;
  final String distance;
}

class AvailableTripData {
  const AvailableTripData({
    required this.vehicleType,
    required this.driverName,
    required this.estimatedArrival,
    required this.routeDuration,
    required this.availableSeats,
    required this.startingPrice,
    required this.vehicleId,
  });

  final String vehicleType;
  final String driverName;
  final String estimatedArrival;
  final String routeDuration;
  final int availableSeats;
  final String startingPrice;
  final String vehicleId;
}

class MapPinOption {
  const MapPinOption({
    required this.label,
    required this.subtitle,
    required this.x,
    required this.y,
  });

  final String label;
  final String subtitle;
  final double x;
  final double y;
}
