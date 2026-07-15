import 'package:flutter/widgets.dart';

import 'package:bmt_app/core/localization/l10n_context.dart';

/// Sort order for Route Details' available-trips list.
enum TripSort { earliest, priceLow, seatsHigh }

String tripSortLabel(BuildContext context, TripSort sort) {
  final l10n = context.l10n;
  return switch (sort) {
    TripSort.earliest => l10n.booking_tripSortEarliestDeparture,
    TripSort.priceLow => l10n.booking_sortLowestPrice,
    TripSort.seatsHigh => l10n.booking_sortMostSeats,
  };
}
