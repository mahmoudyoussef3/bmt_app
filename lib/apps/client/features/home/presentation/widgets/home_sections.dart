import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/routes/client_routes.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_departing_soon_list.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_entrance.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_live_trip_card.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_package_banner.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_packages_section.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_section_header.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_support_tile.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/popular_routes_preview.dart';

/// Everything below the hero: current journey, departing soon, popular
/// routes, packages and support — each revealed with a staggered entrance.
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

  @override
  Widget build(BuildContext context) {
    var order = 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (data.currentTrip != null) ...[
          HomeEntrance(
            order: order++,
            child: _Section(
              header: const HomeSectionHeader(
                eyebrow: 'Your journey',
                title: 'Ready when you are',
              ),
              child: HomeLiveTripCard(
                trip: data.currentTrip!,
                onTap: () => onOpenRoute(ClientRoutes.tracking, {
                  'bookingId': data.currentTrip!.id,
                }),
              ),
            ),
          ),
          const SizedBox(height: ClientSpacing.xl),
        ],
        if (data.nearbyTrips.isNotEmpty) ...[
          HomeEntrance(
            order: order++,
            child: _Section(
              header: const HomeSectionHeader(
                eyebrow: 'Leaving soon',
                title: 'Departing today',
                subtitle: 'Live trips you can still hop on.',
              ),
              child: HomeDepartingSoonList(
                trips: data.nearbyTrips,
                onSelect: (trip) =>
                    onOpenRoute(ClientRoutes.bookingRouteSelection, {
                      'pickup': trip.pickup,
                      'destination': trip.destination,
                      'date': DateTime.now().toIso8601String().split('T').first,
                      'time': trip.departureTime,
                    }),
              ),
            ),
          ),
          const SizedBox(height: ClientSpacing.xl),
        ],
        HomeEntrance(
          order: order++,
          child: _Section(
            header: HomeSectionHeader(
              eyebrow: 'Discover',
              title: 'Popular routes',
              actionLabel: 'View all',
              onAction: () => onOpenRoute(ClientRoutes.bookingPopularRoutes),
            ),
            child: PopularRoutesPreview(
              routes: data.popularRoutes,
              previewCount: isTablet ? 4 : 3,
              onOpenRoute: onOpenRoute,
            ),
          ),
        ),
        if (data.activePackage == null) ...[
          const SizedBox(height: ClientSpacing.xl),
          HomeEntrance(
            order: order++,
            child: HomePackageBanner(onTap: _openSubscription),
          ),
        ],
        const SizedBox(height: ClientSpacing.xl),
        HomeEntrance(
          order: order++,
          child: HomePackagesSection(
            plans: data.packagePlans,
            activePackage: data.activePackage,
            previewCount: isTablet ? 4 : 3,
            onOpenSubscription: _openSubscription,
          ),
        ),
        const SizedBox(height: ClientSpacing.xl),
        HomeEntrance(
          order: order++,
          child: HomeSupportTile(
            onTap: () => onOpenRoute(ClientRoutes.support),
          ),
        ),
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
