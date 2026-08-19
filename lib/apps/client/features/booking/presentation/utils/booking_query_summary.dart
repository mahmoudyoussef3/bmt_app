import 'package:flutter/widgets.dart';

import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/route_direction_text.dart';

import '../../domain/entities/booking_search_query.dart';

/// One line describing the search the rider is inside: where they are going,
/// then when.
///
/// Lives here rather than on [BookingSearchQuery] because the endpoints cannot
/// be joined without knowing which way the reader's text runs — see
/// [routeDirectionLabel].
String bookingQuerySummary(BookingSearchQuery query, BuildContext context) {
  if (!query.isComplete) return context.l10n.booking_setPickupAndDestination;

  final route = routeDirectionLabel(
    query.pickup,
    query.destination,
    direction: Directionality.of(context),
  );
  final schedule = query.scheduleLine.trim();
  return schedule.isEmpty ? route : '$route · $schedule';
}
