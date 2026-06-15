class RouteOptionData {
  const RouteOptionData({
    required this.id,
    required this.pickup,
    required this.destination,
    required this.duration,
    required this.availableSeats,
    required this.startingPrice,
    this.points = const [],
    this.isFastest = false,
  });

  final String id;
  final String pickup;
  final String destination;
  final String duration;
  final int availableSeats;
  final String startingPrice;
  final List<RoutePointData> points;
  final bool isFastest;
}

class RoutePointData {
  const RoutePointData({
    required this.name,
    required this.order,
    this.latitude,
    this.longitude,
  });

  final String name;
  final int order;
  final double? latitude;
  final double? longitude;
}

class PopularRouteListData {
  const PopularRouteListData({
    required this.routeName,
    required this.dailyTrips,
    required this.averageDuration,
    required this.startingPrice,
    required this.pickup,
    required this.destination,
  });

  final String routeName;
  final int dailyTrips;
  final String averageDuration;
  final String startingPrice;
  final String pickup;
  final String destination;
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
