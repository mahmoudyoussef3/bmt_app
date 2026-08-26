import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/widgets/client_segmented_tabs.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_filter_count_badge.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

String _filterLabel(BuildContext context, TripFilter filter) {
  return switch (filter) {
    TripFilter.upcoming => context.l10n.trips_filterUpcoming,
    TripFilter.active => context.l10n.trips_filterActive,
    TripFilter.completed => context.l10n.trips_filterCompleted,
    TripFilter.cancelled => context.l10n.trips_filterCancelled,
  };
}

/// The four views of My Trips, as the design's segmented control.
///
/// Was a horizontally scrolling row of pills inside a card, which hid the
/// fourth filter off-screen on a narrow phone and framed a control as content.
/// The four filters are a fixed, complete set — the shape that says so is a
/// segmented track where all four are visible at once.
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
    const filters = TripFilter.values;

    return ClientSegmentedTabs(
      selectedIndex: filters.indexOf(selected),
      onSelected: (index) => onSelected(filters[index]),
      segments: [
        for (final filter in filters)
          ClientSegment(
            label: _filterLabel(context, filter),
            trailing: (counts?[filter] ?? 0) > 0
                ? TripFilterCountBadge(
                    count: counts![filter]!,
                    active: selected == filter,
                  )
                : null,
          ),
      ],
    );
  }
}
