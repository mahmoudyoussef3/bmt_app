import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_routes.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/easyway_route_map_view.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/no_map_placeholder.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_overview_fare_action.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_overview_hero.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_overview_meta_row.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_overview_stop_timeline.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// A secondary, simpler route-details variant. Registered at
/// `BookingRoutes.routeOverview` but not currently reachable from any
/// in-app navigation call — kept in sync with the shared design system
/// (see specs/002-bmt-routes-booking-ux/tasks.md T026) without further
/// premium investment until it is wired up or removed.
class RouteOverviewScreen extends StatelessWidget {
  const RouteOverviewScreen({super.key, required this.route});
  final RouteOptionData route;

  List<RoutePointData> get _sortedStops =>
      [...route.points]..sort((a, b) => a.order.compareTo(b.order));

  @override
  Widget build(BuildContext context) {
    final stops = _sortedStops;
    final mapPins = stops
        .where(_hasValidCoordinates)
        .map(
          (stop) => MapPinOption(
            label: stop.name,
            subtitle: '',
            x: stop.latitude!,
            y: stop.longitude!,
          ),
        )
        .toList();
    return Scaffold(
      backgroundColor: ClientColors.surfaceSubtleFor(context),
      bottomNavigationBar: RouteOverviewFareAction(
        startingPrice: route.startingPrice,
        onChooseRoute: () => Navigator.of(
          context,
        ).pushNamed(BookingRoutes.wizard, arguments: route),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: ClientColors.surfaceFor(context),
            leading: const BackButton(),
            title: Text(
              route.routeName,
              style: ClientTypography.bodyMedium(
                context,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: mapPins.isNotEmpty
                  ? EasyWayRouteMapView(
                      waypoints: mapPins,
                      cameraPadding: const EdgeInsets.fromLTRB(42, 72, 42, 36),
                      info: RouteMapInfoData(
                        distance: route.distance,
                        duration: route.duration,
                        availableSeats: route.availableSeats,
                      ),
                    )
                  : const NoMapPlaceholder(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RouteOverviewHero(route: route, stops: stops),
                  const SizedBox(height: 16),
                  RouteOverviewMetaRow(route: route),
                  const SizedBox(height: 20),
                  Text(
                    context.l10n.booking_allStopsCount(stops.length),
                    style: ClientTypography.labelMedium(
                      context,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  RouteOverviewStopTimeline(stops: stops),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasValidCoordinates(RoutePointData point) {
    final latitude = point.latitude;
    final longitude = point.longitude;
    return latitude != null &&
        longitude != null &&
        latitude.isFinite &&
        longitude.isFinite &&
        (latitude != 0 || longitude != 0) &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }
}
