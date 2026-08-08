import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_upcoming_trip_card.dart';

/// The departure board on Home: every trip a rider can take a seat on, soonest
/// first.
///
/// A sliver rather than a boxed column — Home carries the whole board, not a
/// teaser slice, so cards are built as they scroll into view instead of all at
/// once. A vertical stack, not a carousel: riders compare departures against
/// each other, and hidden cards do not get booked.
class HomeUpcomingTripsList extends StatelessWidget {
  const HomeUpcomingTripsList({
    super.key,
    required this.trips,
    required this.onBook,
    required this.onBrowseRoutes,
  });

  final List<UpcomingTripData> trips;
  final ValueChanged<UpcomingTripData> onBook;
  final VoidCallback onBrowseRoutes;

  @override
  Widget build(BuildContext context) {
    if (trips.isEmpty) {
      return SliverToBoxAdapter(
        child: _NoDepartures(onBrowseRoutes: onBrowseRoutes),
      );
    }

    return SliverList.separated(
      itemCount: trips.length,
      separatorBuilder: (_, _) => const SizedBox(height: ClientSpacing.sm),
      itemBuilder: (context, index) {
        final trip = trips[index];
        return HomeUpcomingTripCard(trip: trip, onBook: () => onBook(trip));
      },
    );
  }
}

/// A calm, centred placeholder rather than a shrunken banner — the departure
/// board's own header already says "nothing to show", so this panel spends its
/// space explaining why and handing the rider the one action that fixes it.
class _NoDepartures extends StatelessWidget {
  const _NoDepartures({required this.onBrowseRoutes});

  final VoidCallback onBrowseRoutes;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: ClientSpacing.lg,
        vertical: ClientSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.lg),
        border: Border.all(color: ClientColors.borderFor(context)),
        boxShadow: ClientElevation.sm(context),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: ClientColors.primaryFor(context).withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_busy_rounded,
              size: 32,
              color: ClientColors.primaryFor(context),
            ),
          ),
          const SizedBox(height: ClientSpacing.md),
          Text(
            context.l10n.home_noDepartures,
            textAlign: TextAlign.center,
            style: ClientTypography.headingSmall(
              context,
            ).copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.home_noDeparturesBody,
            textAlign: TextAlign.center,
            style: ClientTypography.bodySmall(
              context,
            ).copyWith(color: ClientColors.textSecondaryFor(context)),
          ),
          const SizedBox(height: ClientSpacing.lg),
          ClientButton(
            label: context.l10n.home_browseRoutes,
            icon: const DirectionalIcon(Icons.arrow_forward_rounded),
            expand: false,
            onPressed: onBrowseRoutes,
          ),
        ],
      ),
    );
  }
}
