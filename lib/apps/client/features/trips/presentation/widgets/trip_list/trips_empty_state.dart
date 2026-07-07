import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';

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
      TripFilter.upcoming => 'No upcoming trips scheduled',
      TripFilter.active => 'No trips in progress right now',
      TripFilter.completed => 'No completed trips yet',
      TripFilter.cancelled => 'No cancelled trips',
    };
    final subtitle = switch (filter) {
      TripFilter.upcoming => 'Book a trip and it will show up here.',
      TripFilter.active => 'Trips currently on the road will appear here.',
      TripFilter.completed => 'Trips you finish will show up here.',
      TripFilter.cancelled => 'Trips you cancel will show up here.',
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
            label: 'Browse routes',
            onPressed: onBrowseRoutes,
            expand: false,
          ),
        ],
      ),
    );
  }
}
