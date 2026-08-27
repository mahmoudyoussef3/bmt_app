import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_upcoming_trip_card.dart';

/// The departure board on Home: the soonest trips a rider can take a seat on,
/// as a column of full-width boarding passes.
///
/// A column, not the side-scrolling rail this used to be. The rail put one
/// departure in front of the rider at a time and hid the rest past the edge of
/// the screen, which is the wrong shape for the one decision this section
/// exists to serve — a rider is choosing *between* departures, and comparing
/// two times means seeing two times. It was also the only horizontal scroller
/// among Home's primary content: the seats they hold and the corridors they can
/// browse are both columns of full-width cards, so the part of the page that
/// actually sells a ticket was the part that looked borrowed.
///
/// The board itself carries up to fifty departures and a phone screen is not a
/// catalog, so Home prints the first [previewCount] and hands the rest to the
/// routes tab. Still a sliver, so its cards build as they scroll in.
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

  /// How many departures Home prints before handing the rider to the full list.
  /// The same three the featured-routes shelf prints, so the two capped
  /// sections on the page are capped alike — and so the corridors a rider goes
  /// looking for when none of these fit are not three screens further down.
  static const int previewCount = 3;

  @override
  Widget build(BuildContext context) {
    // Home drops the whole departures zone — its header included — when nothing
    // is on sale, so an empty board here draws nothing rather than leaving a
    // stray "view all" behind.
    if (trips.isEmpty) return const SliverToBoxAdapter();

    final visible = trips.take(previewCount).toList();

    return SliverMainAxisGroup(
      slivers: [
        SliverList.separated(
          itemCount: visible.length,
          separatorBuilder: (_, _) => const SizedBox(height: ClientSpacing.md),
          itemBuilder: (context, index) => HomeUpcomingTripCard(
            trip: visible[index],
            onBook: () => onBook(visible[index]),
          ),
        ),
        // Only when there is actually something past the fold: a "view all"
        // under a board that already shows everything is a dead end dressed up
        // as a door.
        if (trips.length > previewCount)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: ClientSpacing.md),
              child: ClientButton.secondary(
                label: context.l10n.home_viewAll,
                icon: const DirectionalIcon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                ),
                onPressed: onBrowseRoutes,
              ),
            ),
          ),
      ],
    );
  }
}
