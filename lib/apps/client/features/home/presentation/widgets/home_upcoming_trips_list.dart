import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_upcoming_trip_card.dart';

/// The single trip feed on Home. A vertical stack, not a carousel: riders
/// compare departures against each other, and hidden cards do not get booked.
class HomeUpcomingTripsList extends StatelessWidget {
  const HomeUpcomingTripsList({
    super.key,
    required this.trips,
    required this.previewCount,
    required this.onBook,
    required this.onBrowseRoutes,
  });

  final List<UpcomingTripData> trips;
  final int previewCount;
  final ValueChanged<UpcomingTripData> onBook;
  final VoidCallback onBrowseRoutes;

  @override
  Widget build(BuildContext context) {
    if (trips.isEmpty) {
      return _NoDepartures(onBrowseRoutes: onBrowseRoutes);
    }

    final visible = trips.take(previewCount).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final trip in visible) ...[
          HomeUpcomingTripCard(trip: trip, onBook: () => onBook(trip)),
          if (trip != visible.last) const SizedBox(height: ClientSpacing.sm),
        ],
      ],
    );
  }
}

class _NoDepartures extends StatelessWidget {
  const _NoDepartures({required this.onBrowseRoutes});

  final VoidCallback onBrowseRoutes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ClientSpacing.md),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.lg),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: ClientColors.primaryFor(context).withAlpha(22),
                  borderRadius: BorderRadius.circular(ClientRadius.sm),
                ),
                child: Icon(
                  Icons.event_busy_rounded,
                  color: ClientColors.primaryFor(context),
                ),
              ),
              const SizedBox(width: ClientSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.home_noDepartures,
                      style: ClientTypography.headingSmall(
                        context,
                      ).copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      context.l10n.home_noDeparturesBody,
                      style: ClientTypography.bodySmall(context).copyWith(
                        color: ClientColors.textSecondaryFor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ClientSpacing.sm),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: onBrowseRoutes,
              child: Text(context.l10n.home_browseRoutes),
            ),
          ),
        ],
      ),
    );
  }
}
