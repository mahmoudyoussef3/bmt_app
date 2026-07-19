import 'package:flutter/material.dart';

import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_filter_pill.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

String _filterLabel(BuildContext context, TripFilter filter) {
  return switch (filter) {
    TripFilter.upcoming => context.l10n.trips_filterUpcoming,
    TripFilter.active => context.l10n.trips_filterActive,
    TripFilter.completed => context.l10n.trips_filterCompleted,
    TripFilter.cancelled => context.l10n.trips_filterCancelled,
  };
}

class TripFilterBar extends StatelessWidget {
  const TripFilterBar({
    super.key,
    required this.selected,
    required this.onSelected,
    this.counts,
  });

  final TripFilter selected;
  final ValueChanged<TripFilter> onSelected;
  final Map<TripFilter, int>? counts;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final filter in TripFilter.values)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: TripFilterPill(
                  label: _filterLabel(context, filter),
                  count: counts?[filter] ?? 0,
                  active: selected == filter,
                  onTap: () => onSelected(filter),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
