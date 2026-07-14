import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/routes/client_routes.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
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

  void _openSubscription() => onOpenRoute(ClientRoutes.subscription, {
    'hasActiveSubscription': data.activePackage != null,
  });

  void _trackBooking(HomeBookingData booking) =>
      onOpenRoute(ClientRoutes.tracking, {'bookingId': booking.id});

  /// Carries the exact departure the rider tapped into the booking flow, so
  /// the route/date/time are already chosen when they land there.
  void _bookTrip(UpcomingTripData trip) =>
      onOpenRoute(ClientRoutes.bookingRouteSelection, {
        'routeId': trip.routeId,
        'pickup': trip.pickup,
        'destination': trip.destination,
        'date': trip.tripDate,
        'time': trip.departureTime,
      });

  @override
  Widget build(BuildContext context) {
    var order = 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (data.bookings.isNotEmpty) ...[
          HomeEntrance(
            order: order++,
            child: _Section(
              header: HomeSectionHeader(
                eyebrow: 'Your journey',
                title: data.bookings.length == 1
                    ? 'Your booking'
                    : 'Your bookings',
                subtitle: 'Seats you hold, and where each one stands.',
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
              eyebrow: 'Book a seat',
              title: 'Next departures',
              subtitle: 'Trips open for booking, soonest first.',
              actionLabel: 'All routes',
              onAction: () => onOpenRoute(ClientRoutes.bookingPopularRoutes),
            ),
            child: HomeUpcomingTripsList(
              trips: data.upcomingTrips,
              previewCount: isTablet ? 4 : 3,
              onBook: _bookTrip,
              onBrowseRoutes: () =>
                  onOpenRoute(ClientRoutes.bookingPopularRoutes),
            ),
          ),
        ),
        if (data.activePackage != null) ...[
          const SizedBox(height: ClientSpacing.xl),
          HomeEntrance(
            order: order++,
            child: _Section(
              header: HomeSectionHeader(
                eyebrow: 'Your package',
                title: 'Active subscription',
                actionLabel: 'Manage',
                onAction: _openSubscription,
              ),
              child: HomeActivePackageCard(
                package: data.activePackage!,
                onTap: _openSubscription,
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
      children: [header, const SizedBox(height: ClientSpacing.md), child],
    );
  }
}
