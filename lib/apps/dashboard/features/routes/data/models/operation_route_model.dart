import '../../domain/entities/operation_route.dart';

class OperationRouteModel extends OperationRoute {
  const OperationRouteModel({
    required super.id,
    required super.name,
    required super.startCity,
    required super.endCity,
    required super.duration,
    required super.distance,
    required super.status,
    required super.stations,
    required super.notes,
  });

  factory OperationRouteModel.fromEntity(OperationRoute route) {
    return OperationRouteModel(
      id: route.id,
      name: route.name,
      startCity: route.startCity,
      endCity: route.endCity,
      duration: route.duration,
      distance: route.distance,
      status: route.status,
      stations: route.stations,
      notes: route.notes,
    );
  }

  factory OperationRouteModel.fromJson(
    Map<String, dynamic> json, {
    List<RouteStation> stations = const [],
  }) {
    return OperationRouteModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      startCity: json['start_city'] as String? ?? '',
      endCity: json['end_city'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      distance: json['distance'] as String? ?? '',
      status: _parseStatus(json['status'] as String?),
      stations: stations,
      notes: _parseNotes(json['notes']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'start_city': startCity,
      'end_city': endCity,
      'duration': duration,
      'distance': distance,
      'status': status.name,
      'notes': notes,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  static OperationRouteStatus _parseStatus(String? value) {
    if (value == null || value.isEmpty) return OperationRouteStatus.draft;
    return OperationRouteStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => OperationRouteStatus.draft,
    );
  }

  static List<String> _parseNotes(dynamic value) {
    if (value == null) return const [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return const [];
  }
}

class RouteStationModel extends RouteStation {
  const RouteStationModel({
    required super.id,
    required super.name,
    required super.area,
    required super.arrivalOffset,
    super.departureOffset,
    super.locationDescription,
    super.notes,
    required super.order,
  });

  factory RouteStationModel.fromJson(Map<String, dynamic> json) {
    return RouteStationModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      area: json['area'] as String? ?? '',
      arrivalOffset: json['arrival_offset'] as String? ?? '',
      departureOffset: json['departure_offset'] as String? ?? '',
      locationDescription: json['location_description'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      order: json['sort_order'] as int? ?? 0,
    );
  }

  factory RouteStationModel.fromEntity(RouteStation station) {
    return RouteStationModel(
      id: station.id,
      name: station.name,
      area: station.area,
      arrivalOffset: station.arrivalOffset,
      departureOffset: station.departureOffset,
      locationDescription: station.locationDescription,
      notes: station.notes,
      order: station.order,
    );
  }

  Map<String, dynamic> toJson({String? routeId}) {
    return {
      'route_id': ?routeId,
      'name': name,
      'area': area,
      'arrival_offset': arrivalOffset,
      'departure_offset': departureOffset,
      'location_description': locationDescription,
      'notes': notes,
      'sort_order': order,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
