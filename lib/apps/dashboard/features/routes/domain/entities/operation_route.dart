enum OperationRouteStatus {
  active('نشط'),
  paused('متوقف مؤقتاً'),
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
  final OperationRouteStatus status;
  final List<RouteStation> stations;
  final List<String> notes;

  const OperationRoute({
    required this.id,
    required this.name,
    required this.startCity,
    required this.endCity,
    required this.duration,
    required this.distance,
    required this.tripsCount,
    required this.status,
    required this.stations,
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
    OperationRouteStatus? status,
    List<RouteStation>? stations,
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
      status: status ?? this.status,
      stations: stations ?? this.stations,
      notes: notes ?? this.notes,
    );
  }
}

class RouteStation {
  final String id;
  final String name;
  final String area;
  final String arrivalOffset;
  final String notes;
  final int order;

  const RouteStation({
    required this.id,
    required this.name,
    required this.area,
    required this.arrivalOffset,
    this.notes = '',
    required this.order,
  });

  RouteStation copyWith({
    String? id,
    String? name,
    String? area,
    String? arrivalOffset,
    String? notes,
    int? order,
  }) {
    return RouteStation(
      id: id ?? this.id,
      name: name ?? this.name,
      area: area ?? this.area,
      arrivalOffset: arrivalOffset ?? this.arrivalOffset,
      notes: notes ?? this.notes,
      order: order ?? this.order,
    );
  }
}
