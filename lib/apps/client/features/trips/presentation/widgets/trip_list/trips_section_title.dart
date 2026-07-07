import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';

/// The section heading above a trip list ("Upcoming trips · 3").
class TripsSectionTitle extends StatelessWidget {
  const TripsSectionTitle({
    super.key,
    required this.filter,
    required this.count,
  });

  final TripFilter filter;
  final int count;

  String get _title {
    return switch (filter) {
      TripFilter.upcoming => 'Upcoming trips',
      TripFilter.active => 'In progress trips',
      TripFilter.completed => 'Completed trips',
      TripFilter.cancelled => 'Cancelled trips',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _title,
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
