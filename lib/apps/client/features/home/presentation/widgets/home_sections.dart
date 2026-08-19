import 'package:bmt_app/apps/client/features/offices/domain/entities/office_summary.dart';
import 'package:bmt_app/apps/client/features/offices/presentation/routes/offices_routes.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/routes/tracking_routes.dart';
import 'package:bmt_app/apps/client/features/packages/presentation/routes/packages_routes.dart';
import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_routes.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_active_package_card.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_bookings_list.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_entrance.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_offices_rail.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_section_header.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_upcoming_trips_list.dart';

/// Everything below the hero, in the order a rider decides in: the seats they
/// already hold, who they can travel with, the full departure board, and their
/// package when they hold one. Support lives in the quick actions, not here.
///
/// A sliver group rather than a column: the departure board carries every
/// bookable trip on the marketplace, so its cards must build lazily as they
/// scroll in. The boxed sections around it keep their staggered entrance.
class HomeSections extends StatelessWidget {
  const HomeSections({
    super.key,
    required this.data,
    required this.offices,
    required this.officesLoading,
    required this.onOpenRoute,
    required this.onSwitchTab,
  });

  final HomeData data;

  /// The operators trading on the marketplace. Empty hides the section
  /// entirely — a rider is never shown an empty shelf.
  final List<OfficeSummary> offices;
  final bool officesLoading;

  final void Function(String route, [Object? arguments]) onOpenRoute;
  final void Function(String tab) onSwitchTab;

  /// The subscription the rider already holds, with its own usage detail.
  void _openMySubscription() => onOpenRoute(PackagesRoutes.mySubscription);

  void _trackBooking(HomeBookingData booking) =>
      onOpenRoute(TrackingRoutes.tracking, {'bookingId': booking.id});

  void _openOffice(OfficeSummary office) =>
      onOpenRoute(OfficesRoutes.profile, office);

  /// Carries the exact departure the rider tapped into the booking flow, so
  /// the route/date/time are already chosen when they land there.
  void _bookTrip(UpcomingTripData trip) =>
      onOpenRoute(BookingRoutes.routeSelection, {
        'routeId': trip.routeId,
        'pickup': trip.pickup,
        'destination': trip.destination,
        'date': trip.tripDate,
        'time': trip.departureTime,
      });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final showOffices = officesLoading || offices.isNotEmpty;
    var order = 2;

    return SliverMainAxisGroup(
      slivers: [
        if (data.bookings.isNotEmpty)
          _BoxSection(
            order: order++,
            header: HomeSectionHeader(
              eyebrow: l10n.home_yourJourney,
              title: data.bookings.length == 1
                  ? l10n.home_yourBooking
                  : l10n.home_yourBookings,
              subtitle: l10n.home_seatsYouHold,
            ),
            child: HomeBookingsList(
              bookings: data.bookings,
              onTrack: _trackBooking,
            ),
          ),
        if (showOffices)
          _BoxSection(
            order: order++,
            header: HomeSectionHeader(
              eyebrow: l10n.home_travelWith,
              title: l10n.home_companies,
              subtitle: l10n.home_companiesSubtitle,
              actionLabel: l10n.home_viewAll,
              onAction: () => onOpenRoute(OfficesRoutes.directory),
            ),
            child: HomeOfficesRail(
              offices: offices,
              isLoading: officesLoading,
              onOpenOffice: _openOffice,
            ),
          ),
        SliverToBoxAdapter(
          child: HomeEntrance(
            order: order++,
            child: Padding(
              padding: const EdgeInsets.only(bottom: ClientSpacing.md),
              child: HomeSectionHeader(
                eyebrow: l10n.home_bookASeat,
                title: l10n.home_nextDepartures,
                subtitle: data.upcomingTrips.isEmpty
                    ? l10n.home_tripsOpenSoonest
                    : l10n.home_departuresOpenCount(data.upcomingTrips.length),
                actionLabel: l10n.home_allRoutes,
                onAction: () => onSwitchTab('routes'),
              ),
            ),
          ),
        ),
        HomeUpcomingTripsList(
          trips: data.upcomingTrips,
          onBook: _bookTrip,
          onBrowseRoutes: () => onSwitchTab('routes'),
        ),
        if (data.activePackage != null)
          _BoxSection(
            order: order++,
            topSpacing: ClientSpacing.xl,
            header: HomeSectionHeader(
              eyebrow: l10n.home_yourPackage,
              title: l10n.home_activeSubscription,
              actionLabel: l10n.common_manage,
              onAction: _openMySubscription,
            ),
            child: HomeActivePackageCard(
              package: data.activePackage!,
              onTap: _openMySubscription,
            ),
          ),
      ],
    );
  }
}

/// A header + its content, revealed together on the staggered entrance.
class _BoxSection extends StatelessWidget {
  const _BoxSection({
    required this.order,
    required this.header,
    required this.child,
    this.topSpacing = 0,
  });

  final int order;
  final Widget header;
  final Widget child;
  final double topSpacing;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: HomeEntrance(
        order: order,
        child: Padding(
          padding: EdgeInsets.only(top: topSpacing, bottom: ClientSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: ClientSpacing.md),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
