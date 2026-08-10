import 'route_stop.dart';

/// A route's full record: identity, the office running it, and every stop on
/// its corridor in order.
class RouteDetails {
  const RouteDetails({
    required this.id,
    required this.name,
    required this.startCity,
    required this.endCity,
    this.routeCode = '',
    this.distance = '',
    this.duration = '',
    this.status = '',
    this.officeId = '',
    this.officeName = '',
    this.officeLogoUrl,
    this.officeRating = 0,
    this.stops = const [],
  });

  final String id;
  final String routeCode;
  final String name;
  final String startCity;
  final String endCity;
  final String distance;
  final String duration;
  final String status;
  final String officeId;
  final String officeName;
  final String? officeLogoUrl;
  final double officeRating;
  final List<RouteStop> stops;
}
