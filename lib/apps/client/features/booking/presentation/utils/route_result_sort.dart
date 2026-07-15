import 'package:flutter/widgets.dart';

import 'package:bmt_app/core/localization/l10n_context.dart';

/// Sort order for the routes discovery/results grid.
enum RouteResultSort { recommended, priceLow, durationShort, tripsHigh }

String routeResultSortLabel(BuildContext context, RouteResultSort sort) {
  final l10n = context.l10n;
  return switch (sort) {
    RouteResultSort.recommended => l10n.booking_sortRecommended,
    RouteResultSort.priceLow => l10n.booking_sortLowestPrice,
    RouteResultSort.durationShort => l10n.booking_sortShortestDuration,
    RouteResultSort.tripsHigh => l10n.booking_sortMostTrips,
  };
}
