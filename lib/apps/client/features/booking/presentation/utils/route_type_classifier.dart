import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';

/// Whether a route runs directly between its endpoints or serves
/// intermediate stops along the way. Purely a display grouping derived from
/// [RouteOptionData.points] — not a stored or fetched field.
enum RouteType { direct, multiStop }

/// A route with two or fewer stops (start + destination, no intermediate
/// pickup/dropoff) reads as direct; anything with more stops is multi-stop.
const _directStopThreshold = 2;

RouteType classifyRouteType(RouteOptionData route) {
  return route.points.length <= _directStopThreshold
      ? RouteType.direct
      : RouteType.multiStop;
}

String routeTypeLabel(RouteType type) {
  return switch (type) {
    RouteType.direct => 'Direct',
    RouteType.multiStop => 'Multi-stop',
  };
}
