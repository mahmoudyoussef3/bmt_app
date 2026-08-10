/// One stop on a route's corridor, in running order.
class RouteStop {
  const RouteStop({
    required this.id,
    required this.name,
    required this.order,
    this.area = '',
    this.arrivalOffset = '',
    this.departureOffset = '',
    this.estimatedArrivalTime = '',
    this.pickupAllowed = true,
    this.dropoffAllowed = true,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String name;
  final int order;
  final String area;
  final String arrivalOffset;
  final String departureOffset;
  final String estimatedArrivalTime;
  final bool pickupAllowed;
  final bool dropoffAllowed;
  final double? latitude;
  final double? longitude;
}
