import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// The section heading above a trip list ("Upcoming trips · 3").
class TripsSectionTitle extends StatelessWidget {
  const TripsSectionTitle({
    super.key,
    required this.filter,
    required this.count,
  });

  final TripFilter filter;
  final int count;

  String _title(BuildContext context) {
    return switch (filter) {
      TripFilter.upcoming => context.l10n.trips_sectionUpcoming,
      TripFilter.active => context.l10n.trips_sectionActive,
      TripFilter.completed => context.l10n.trips_sectionCompleted,
      TripFilter.cancelled => context.l10n.trips_sectionCancelled,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _title(context),
          style: Theme.of(
            context,
          ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(
          '$count',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
