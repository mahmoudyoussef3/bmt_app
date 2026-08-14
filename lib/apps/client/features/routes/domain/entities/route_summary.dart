import 'route_stop.dart';

/// One route as it appears in the client's routes catalog: just enough to
/// recognise the corridor and who runs it before opening its full details.
class RouteSummary {
  const RouteSummary({
    required this.id,
    required this.name,
    required this.startCity,
    required this.endCity,
    this.distance = '',
    this.duration = '',
    this.officeId = '',
    this.officeName = '',
    this.officeLogoUrl,
    this.stops = const [],
  });

  final String id;
  final String name;
  final String startCity;
  final String endCity;
  final String distance;
  final String duration;
  final String officeId;
  final String officeName;
  final String? officeLogoUrl;

  /// The corridor's stops in running order — carried on the catalog row so a
  /// rider can search for a town the route merely *passes through*, which is
  /// the question they are actually asking ("can I get on at Banha?").
  ///
  /// Identity and order only: the catalog reads names, not timings or boarding
  /// rules, so every other [RouteStop] field here sits at its default. Anything
  /// that needs a real timetable loads the route's details instead.
  final List<RouteStop> stops;
}
