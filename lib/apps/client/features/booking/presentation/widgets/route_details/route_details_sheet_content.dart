import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/closest_match_banner.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/route_alternatives_section.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/route_available_trips_section.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/route_overview_header.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/route_pricing_card.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/route_stop_timeline.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/theme/app_layout.dart';

/// The scrollable content inside Route Details' draggable sheet: banner,
/// overview, stop timeline, pricing, available trips, and alternatives.
class RouteDetailsSheetContent extends StatelessWidget {
  const RouteDetailsSheetContent({
    super.key,
    required this.scrollController,
    required this.route,
    required this.routes,
    required this.orderedPoints,
    required this.selectedTripId,
    required this.onMap,
    required this.onSelectRoute,
    required this.onSelectTrip,
  });

  final ScrollController scrollController;
  final RouteOptionData route;
  final List<RouteOptionData> routes;
  final List<RoutePointData> orderedPoints;
  final String? selectedTripId;
  final VoidCallback onMap;
  final ValueChanged<RouteOptionData> onSelectRoute;
  final ValueChanged<RouteTripOptionData> onSelectTrip;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: AppLayout.maxContentWidth(MediaQuery.sizeOf(context).width),
        ),
        child: _content(context),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 110),
      children: [
        Center(
          child: Semantics(
            label: l10n.booking_dragToExpandDetails,
            child: Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline.withAlpha(80),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        if (!route.isExactMatch) ...[
          ClosestMatchBanner(quality: route.matchQuality),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: Text(
                route.isExactMatch
                    ? l10n.booking_isThisRouteSuitable
                    : l10n.booking_closestRoutesForSearch,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onMap,
              icon: const Icon(Icons.edit_location_alt_rounded, size: 18),
              label: Text(l10n.booking_editStops),
            ),
          ],
        ),
        const SizedBox(height: 12),
        RouteOverviewHeader(route: route),
        const SizedBox(height: 14),
        RouteStopTimeline(points: orderedPoints),
        const SizedBox(height: 14),
        RoutePricingCard(route: route),
        const SizedBox(height: 14),
        RouteAvailableTripsSection(
          trips: route.availableTrips,
          hasRoutePricing:
              route.startingPrice.trim().toLowerCase() != 'price pending',
          selectedTripId: selectedTripId,
          onSelectTrip: onSelectTrip,
        ),
        if (routes.length > 1) ...[
          const SizedBox(height: 18),
          RouteAlternativesSection(
            routes: routes,
            selectedRouteId: route.id,
            onSelectRoute: onSelectRoute,
          ),
        ],
      ],
    );
  }
}
