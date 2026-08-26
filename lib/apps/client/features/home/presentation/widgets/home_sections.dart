import 'package:bmt_app/apps/client/features/offices/domain/entities/office_summary.dart';
import 'package:bmt_app/apps/client/features/offices/presentation/routes/offices_routes.dart';
import 'package:bmt_app/apps/client/features/routes/domain/entities/route_summary.dart';
import 'package:bmt_app/apps/client/features/routes/presentation/routes/routes_feature_routes.dart';
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
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_featured_routes_section.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_live_trip_banner.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_offices_rail.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_section_header.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_upcoming_trips_list.dart';

/// Everything below the hero, in three zones a rider reads in order:
///
/// 1. **Yours** — the live seat, the other seats being held, the subscription
///    being paid for. Personal state, and the only thing on the page that is
///    already true.
/// 2. **Book** — the departure board: every trip the marketplace can sell
///    right now. This is what Home exists for, so nothing browsable is
///    allowed above it. With nothing on sale the whole zone — header
///    included — is dropped rather than announced and then apologised for;
///    the quick actions and the discovery shelves already carry a rider to
///    the route list.
/// 3. **Discover** — featured corridors and the operators running them. Both
///    are shelves into tabs of their own; they are where a rider goes when
///    the board did not have their trip, so they close the page.
///
/// The zones used to be interleaved — two discovery shelves sat between the
/// rider's own trip and the board that sells them a seat, which put the
/// page's whole purpose three screens down. Grouping them puts what is true
/// first, what is buyable second, and what is browsable last.
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
    required this.featuredRoutes,
    required this.featuredRoutesLoading,
    required this.onOpenRoute,
    required this.onSwitchTab,
  });

  final HomeData data;

  /// The operators trading on the marketplace. Empty hides the section
  /// entirely — a rider is never shown an empty shelf.
  final List<OfficeSummary> offices;
  final bool officesLoading;

  /// The routes catalog's shelf of corridors. Empty hides the section too.
  final List<RouteSummary> featuredRoutes;
  final bool featuredRoutesLoading;

  final void Function(String route, [Object? arguments]) onOpenRoute;
  final void Function(String tab) onSwitchTab;

  /// The gap under every zone member, so the page keeps one vertical rhythm
  /// whichever sections a given rider actually has.
  static const double _blockGap = ClientSpacing.xl;

  /// The subscription the rider already holds, with its own usage detail.
  void _openMySubscription() => onOpenRoute(PackagesRoutes.mySubscription);

  void _trackBooking(HomeBookingData booking) =>
      onOpenRoute(TrackingRoutes.tracking, {'bookingId': booking.id});

  void _openOffice(OfficeSummary office) =>
      onOpenRoute(OfficesRoutes.profile, office);

  void _openFeaturedRoute(RouteSummary route) =>
      onOpenRoute(RoutesFeatureRoutes.details, {'routeId': route.id});

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
    final showFeaturedRoutes =
        featuredRoutesLoading || featuredRoutes.isNotEmpty;
    var order = 2;

    // The soonest booking a rider can actually follow gets the hero
    // treatment up front; the rest — and an under-review booking with
    // nothing to track yet — keep the plainer boarding-pass list below.
    final liveBooking =
        data.bookings.isNotEmpty && data.bookings.first.status.isTrackable
        ? data.bookings.first
        : null;
    final remainingBookings = liveBooking == null
        ? data.bookings
        : data.bookings.skip(1).toList();

    return SliverMainAxisGroup(
      slivers: [
        // ── Yours ──────────────────────────────────────────────────────
        if (liveBooking != null)
          SliverToBoxAdapter(
            child: HomeEntrance(
              order: order++,
              child: Padding(
                padding: const EdgeInsets.only(bottom: _blockGap),
                child: HomeLiveTripBanner(
                  booking: liveBooking,
                  onTrack: () => _trackBooking(liveBooking),
                ),
              ),
            ),
          ),
        if (remainingBookings.isNotEmpty)
          _BoxSection(
            order: order++,
            header: HomeSectionHeader(
              title: remainingBookings.length == 1
                  ? l10n.home_yourBooking
                  : l10n.home_yourBookings,
              subtitle: l10n.home_seatsYouHold,
            ),
            child: HomeBookingsList(
              bookings: remainingBookings,
              onTrack: _trackBooking,
            ),
          ),
        if (data.activePackage != null)
          _BoxSection(
            order: order++,
            header: HomeSectionHeader(
              title: l10n.home_activeSubscription,
              actionLabel: l10n.common_manage,
              onAction: _openMySubscription,
            ),
            child: HomeActivePackageCard(
              package: data.activePackage!,
              onTap: _openMySubscription,
            ),
          ),

        // ── Book ───────────────────────────────────────────────────────
        if (data.upcomingTrips.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: HomeEntrance(
              order: order++,
              child: Padding(
                padding: const EdgeInsets.only(bottom: ClientSpacing.md),
                child: HomeSectionHeader(
                  title: l10n.home_nextDepartures,
                  subtitle: l10n.home_departuresOpenCount(
                    data.upcomingTrips.length,
                  ),
                  actionLabel: l10n.home_allRoutes,
                  onAction: () => onSwitchTab('routes'),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(bottom: _blockGap),
            sliver: HomeUpcomingTripsList(
              trips: data.upcomingTrips,
              onBook: _bookTrip,
              onBrowseRoutes: () => onSwitchTab('routes'),
            ),
          ),
        ],

        // ── Discover ───────────────────────────────────────────────────
        if (showFeaturedRoutes)
          HomeFeaturedRoutesSection(
            routes: featuredRoutes,
            isLoading: featuredRoutesLoading,
            order: order++,
            onOpenRoute: _openFeaturedRoute,
            onViewAll: () => onSwitchTab('routes'),
          ),
        if (showOffices)
          _BoxSection(
            order: order++,
            header: HomeSectionHeader(
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
  });

  final int order;
  final Widget header;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: HomeEntrance(
        order: order,
        child: Padding(
          padding: const EdgeInsets.only(bottom: HomeSections._blockGap),
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
