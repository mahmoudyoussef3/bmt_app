import '../../domain/entities/route_stop.dart';

/// Wire shape of a `route_stations` row.
class RouteStopModel extends RouteStop {
  const RouteStopModel({
    required super.id,
    required super.name,
    required super.order,
    super.area,
    super.arrivalOffset,
    super.departureOffset,
    super.estimatedArrivalTime,
    super.pickupAllowed,
    super.dropoffAllowed,
    super.latitude,
    super.longitude,
  });

  factory RouteStopModel.fromJson(Map<String, dynamic> json) {
    return RouteStopModel(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      order: (json['sort_order'] as num?)?.toInt() ?? 0,
      area: (json['area'] as String?) ?? '',
      arrivalOffset: (json['arrival_offset'] as String?) ?? '',
      departureOffset: (json['departure_offset'] as String?) ?? '',
      estimatedArrivalTime: (json['estimated_arrival_time'] as String?) ?? '',
      pickupAllowed: (json['pickup_allowed'] as bool?) ?? true,
      dropoffAllowed: (json['dropoff_allowed'] as bool?) ?? true,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}
