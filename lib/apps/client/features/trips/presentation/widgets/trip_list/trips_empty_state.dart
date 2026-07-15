import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// A tailored empty state per trip filter, each with a "browse routes"
/// action (spec FR-012) — never a bare icon-and-text dead end.
class TripsEmptyState extends StatelessWidget {
  const TripsEmptyState({
    super.key,
    required this.filter,
    required this.onBrowseRoutes,
  });

  final TripFilter filter;
  final VoidCallback onBrowseRoutes;

  @override
  Widget build(BuildContext context) {
    final message = switch (filter) {
      TripFilter.upcoming => context.l10n.trips_emptyUpcomingTitle,
      TripFilter.active => context.l10n.trips_emptyActiveTitle,
      TripFilter.completed => context.l10n.trips_emptyCompletedTitle,
      TripFilter.cancelled => context.l10n.trips_emptyCancelledTitle,
    };
    final subtitle = switch (filter) {
      TripFilter.upcoming => context.l10n.trips_emptyUpcomingSubtitle,
      TripFilter.active => context.l10n.trips_emptyActiveSubtitle,
      TripFilter.completed => context.l10n.trips_emptyCompletedSubtitle,
      TripFilter.cancelled => context.l10n.trips_emptyCancelledSubtitle,
    };

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy_rounded,
            size: 64,
            color: ClientColors.textTertiaryFor(context),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: ClientTypography.headingSmall(context),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: ClientTypography.bodyMedium(
              context,
            ).copyWith(color: ClientColors.textSecondaryFor(context)),
          ),
          const SizedBox(height: 18),
          ClientButton(
            label: context.l10n.home_browseRoutes,
            onPressed: onBrowseRoutes,
            expand: false,
          ),
        ],
      ),
    );
  }
}
