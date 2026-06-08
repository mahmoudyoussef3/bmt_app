enum OperationRouteStatus {
  active('نشط'),
  paused('متوقف'),
  draft('مسودة'),
  archived('مؤرشف');

  final String label;

  const OperationRouteStatus(this.label);
}

class OperationRoute {
  final String id;
  final String name;
  final String startCity;
  final String endCity;
  final String duration;
  final String distance;
  final int tripsCount;
  final int activePackagesCount;
  final OperationRouteStatus status;
  final List<RouteStation> stations;
  final List<RouteActiveTrip> activeTrips;
  final List<RoutePackage> packages;
  final RouteStatistics statistics;
  final List<String> notes;

  const OperationRoute({
    required this.id,
    required this.name,
    required this.startCity,
    required this.endCity,
    required this.duration,
    required this.distance,
    required this.tripsCount,
    this.activePackagesCount = 0,
    required this.status,
    required this.stations,
    this.activeTrips = const [],
    this.packages = const [],
    this.statistics = const RouteStatistics(
      tripsCount: 0,
      bookingsCount: 0,
      averageOccupancy: '٠٪',
      subscribersCount: 0,
    ),
    required this.notes,
  });

  OperationRoute copyWith({
    String? id,
    String? name,
    String? startCity,
    String? endCity,
    String? duration,
    String? distance,
    int? tripsCount,
    int? activePackagesCount,
    OperationRouteStatus? status,
    List<RouteStation>? stations,
    List<RouteActiveTrip>? activeTrips,
    List<RoutePackage>? packages,
    RouteStatistics? statistics,
    List<String>? notes,
  }) {
    return OperationRoute(
      id: id ?? this.id,
      name: name ?? this.name,
      startCity: startCity ?? this.startCity,
      endCity: endCity ?? this.endCity,
      duration: duration ?? this.duration,
      distance: distance ?? this.distance,
      tripsCount: tripsCount ?? this.tripsCount,
      activePackagesCount: activePackagesCount ?? this.activePackagesCount,
      status: status ?? this.status,
      stations: stations ?? this.stations,
      activeTrips: activeTrips ?? this.activeTrips,
      packages: packages ?? this.packages,
      statistics: statistics ?? this.statistics,
      notes: notes ?? this.notes,
    );
  }
}

class RouteStation {
  final String id;
  final String name;
  final String area;
  final String arrivalOffset;
  final String departureOffset;
  final String locationDescription;
  final String notes;
  final int order;

  const RouteStation({
    required this.id,
    required this.name,
    required this.area,
    required this.arrivalOffset,
    this.departureOffset = '',
    this.locationDescription = '',
    this.notes = '',
    required this.order,
  });

  RouteStation copyWith({
    String? id,
    String? name,
    String? area,
    String? arrivalOffset,
    String? departureOffset,
    String? locationDescription,
    String? notes,
    int? order,
  }) {
    return RouteStation(
      id: id ?? this.id,
      name: name ?? this.name,
      area: area ?? this.area,
      arrivalOffset: arrivalOffset ?? this.arrivalOffset,
      departureOffset: departureOffset ?? this.departureOffset,
      locationDescription: locationDescription ?? this.locationDescription,
      notes: notes ?? this.notes,
      order: order ?? this.order,
    );
  }
}

class RouteActiveTrip {
  final String tripNumber;
  final String driver;
  final String vehicle;
  final int passengersCount;
  final String status;

  const RouteActiveTrip({
    required this.tripNumber,
    required this.driver,
    required this.vehicle,
    required this.passengersCount,
    required this.status,
  });
}

class RoutePackage {
  final String name;
  final String type;
  final String price;
  final int subscribersCount;
  final String status;

  const RoutePackage({
    required this.name,
    required this.type,
    required this.price,
    required this.subscribersCount,
    required this.status,
  });
}

class RouteStatistics {
  final int tripsCount;
  final int bookingsCount;
  final String averageOccupancy;
  final int subscribersCount;

  const RouteStatistics({
    required this.tripsCount,
    required this.bookingsCount,
    required this.averageOccupancy,
    required this.subscribersCount,
  });
}
