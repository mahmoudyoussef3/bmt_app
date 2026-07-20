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
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_section_header.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_upcoming_trips_list.dart';

/// Everything below the hero: the seats the rider already holds, the departures
/// feed, and their package when they hold one — each revealed with a staggered
/// entrance. Support lives in the quick actions, not here.
class HomeSections extends StatelessWidget {
  const HomeSections({
    super.key,
    required this.data,
    required this.isTablet,
    required this.onOpenRoute,
  });

  final HomeData data;
  final bool isTablet;
  final void Function(String route, [Object? arguments]) onOpenRoute;

  /// The subscription the rider already holds — its own usage detail, not
  /// the plan catalogue [PackagesRoutes.subscription] sells.
  void _openMySubscription() => onOpenRoute(PackagesRoutes.mySubscription);

  void _trackBooking(HomeBookingData booking) =>
      onOpenRoute(TrackingRoutes.tracking, {'bookingId': booking.id});

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
    var order = 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (data.bookings.isNotEmpty) ...[
          HomeEntrance(
            order: order++,
            child: _Section(
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
          ),
          const SizedBox(height: ClientSpacing.xl),
        ],
        HomeEntrance(
          order: order++,
          child: _Section(
            header: HomeSectionHeader(
              eyebrow: l10n.home_bookASeat,
              title: l10n.home_nextDepartures,
              subtitle: l10n.home_tripsOpenSoonest,
              actionLabel: l10n.home_allRoutes,
              onAction: () => onOpenRoute(BookingRoutes.popularRoutes),
            ),
            child: HomeUpcomingTripsList(
              trips: data.upcomingTrips,
              previewCount: isTablet ? 4 : 3,
              onBook: _bookTrip,
              onBrowseRoutes: () => onOpenRoute(BookingRoutes.popularRoutes),
            ),
          ),
        ),
        if (data.activePackage != null) ...[
          const SizedBox(height: ClientSpacing.xl),
          HomeEntrance(
            order: order++,
            child: _Section(
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
          ),
        ],
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.header, required this.child});

  final Widget header;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: ClientSpacing.md),
        child,
      ],
    );
  }
}
