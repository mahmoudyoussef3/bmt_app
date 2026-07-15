import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/models/trip_filter_criteria.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/available_trips_header.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/route_details_inline_empty.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/trip_filter_sheet_content.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/trip_option_tile.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Route Details' "available trips" card: every departure for the selected
/// route, filterable by price/seats/vehicle type/time of day (research.md §2)
/// — the one section with real data behind all of spec FR-002's dimensions.
class RouteAvailableTripsSection extends StatefulWidget {
  const RouteAvailableTripsSection({
    super.key,
    required this.trips,
    required this.hasRoutePricing,
    required this.selectedTripId,
    required this.onSelectTrip,
  });

  final List<RouteTripOptionData> trips;
  final bool hasRoutePricing;
  final String? selectedTripId;
  final ValueChanged<RouteTripOptionData> onSelectTrip;

  @override
  State<RouteAvailableTripsSection> createState() =>
      _RouteAvailableTripsSectionState();
}

class _RouteAvailableTripsSectionState
    extends State<RouteAvailableTripsSection> {
  TripFilterCriteria _criteria = const TripFilterCriteria();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final filtered = [...widget.trips.where(_criteria.matches)]
      ..sort(_criteria.compare);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AvailableTripsHeader(
            showFilters: widget.trips.isNotEmpty,
            activeFilters: _criteria.activeCount,
            onOpenFilters: _openFilters,
          ),
          const SizedBox(height: 14),
          if (widget.trips.isEmpty)
            RouteDetailsInlineEmpty(
              icon: Icons.event_busy_rounded,
              title: widget.hasRoutePricing
                  ? l10n.booking_noBookableTripsNow
                  : l10n.booking_noScheduledTripsYet,
              subtitle: widget.hasRoutePricing
                  ? l10n.booking_routeHasPricingNoTrip
                  : l10n.booking_tripsFromDashboardAppear,
            )
          else if (filtered.isEmpty)
            RouteDetailsInlineEmpty(
              icon: Icons.filter_alt_off_rounded,
              title: l10n.booking_noTripsMatchFilters,
              subtitle: l10n.booking_tryWideningFilterRange,
            )
          else
            ...filtered.map(
              (trip) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TripOptionTile(
                  trip: trip,
                  selected: widget.selectedTripId == trip.id,
                  onTap: () => widget.onSelectTrip(trip),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openFilters() async {
    final result = await showTripFilterSheet(
      context: context,
      trips: widget.trips,
      criteria: _criteria,
    );
    if (result != null) setState(() => _criteria = result);
  }
}
