import 'package:flutter/widgets.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

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

String routeTypeLabel(BuildContext context, RouteType type) {
  final l10n = context.l10n;
  return switch (type) {
    RouteType.direct => l10n.booking_routeTypeDirect,
    RouteType.multiStop => l10n.booking_routeTypeMultiStop,
  };
}
