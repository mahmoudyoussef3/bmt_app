import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/widgets/client_error_card.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/route_alternatives_section.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/route_details_map_hero.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/route_details_skeleton.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/route_empty_state.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/route_identity_card.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/route_stop_timeline.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/stop_schedule_labels.dart';
import 'package:bmt_app/core/theme/app_layout.dart';

/// Route Details' body: a map of the line, what the line is, the stations it
/// serves and when the bus is expected at each, and the other lines that also
/// answer the search.
///
/// **What this screen deliberately does not carry.** It used to also price the
/// route, list selectable departures with a fare each, sell commute packages
/// and badge the operator — five decisions stacked on the one screen whose
/// only question is *is this the right line?*. Every one of those is settled
/// later, by a wizard step built for it (stops → trip → seat → package →
/// summary → payment), and every price among them depends on a pickup and
/// drop-off the rider has not chosen yet. Quoting one here would be quoting a
/// journey they have not described.
///
/// The timetable card went the same way. It listed the very departures the
/// wizard's trip step lists, which asked the rider to read the same decision
/// twice and answer it once; the one thing it was really carrying — *when* the
/// line runs — now lands where it is useful, as the estimated clock beside
/// each station.
///
/// The layout is a plain vertical scroll rather than the old draggable sheet
/// over a live map. That fixes the gesture ambiguity (a drag meant either
/// *pan the map* or *move the sheet*), and it lets the stations — the thing a
/// rider is actually here to read — occupy the screen instead of a 48%-tall
/// window over it.
class RouteDetailsBody extends StatelessWidget {
  const RouteDetailsBody({
    super.key,
    required this.isLoading,
    required this.errorMessage,
    required this.routes,
    required this.selectedRoute,
    required this.onRetry,
    required this.onMap,
    required this.onSelectRoute,
  });

  final bool isLoading;
  final String? errorMessage;
  final List<RouteOptionData> routes;
  final RouteOptionData? selectedRoute;
  final VoidCallback onRetry;

  /// Opens this line's full-screen map: every station on it, plotted and
  /// tappable. It used to open the *stop picker* instead, which answered a
  /// question the rider had already answered by arriving here.
  final VoidCallback onMap;

  final ValueChanged<RouteOptionData> onSelectRoute;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const RouteDetailsSkeleton();
    if (errorMessage != null) {
      return ClientErrorCard.fullScreen(
        message: errorMessage!,
        onRetry: onRetry,
      );
    }

    final route = selectedRoute;
    if (route == null) return RouteEmptyState(onRetry: onRetry);

    return ColoredBox(
      color: ClientColors.backgroundFor(context),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AppLayout.maxContentWidth(
              MediaQuery.sizeOf(context).width,
            ),
          ),
          child: _Sections(
            key: ValueKey(route.id),
            route: route,
            routes: routes,
            onMap: onMap,
            onSelectRoute: onSelectRoute,
          ),
        ),
      ),
    );
  }
}

class _Sections extends StatelessWidget {
  const _Sections({
    super.key,
    required this.route,
    required this.routes,
    required this.onMap,
    required this.onSelectRoute,
  });

  final RouteOptionData route;
  final List<RouteOptionData> routes;
  final VoidCallback onMap;
  final ValueChanged<RouteOptionData> onSelectRoute;

  @override
  Widget build(BuildContext context) {
    final orderedPoints = [...route.points]
      ..sort((a, b) => a.order.compareTo(b.order));

    return ListView(
      // The trailing inset clears the sticky booking bar, which floats over
      // the scroll rather than shortening it.
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        RouteDetailsMapHero(
          routeId: route.id,
          mapPins: _mapPins(orderedPoints),
          stopCount: orderedPoints.length,
          onOpenMap: onMap,
        ),
        const SizedBox(height: 14),
        RouteIdentityCard(route: route, stopCount: orderedPoints.length),
        const SizedBox(height: 14),
        RouteStopTimeline(
          points: orderedPoints,
          referenceDeparture: referenceDepartureOf(route.availableTrips),
        ),
        if (routes.length > 1) ...[
          const SizedBox(height: 14),
          RouteAlternativesSection(
            routes: routes,
            selectedRouteId: route.id,
            onSelectRoute: onSelectRoute,
          ),
        ],
      ],
    );
  }

  /// Pins for the hero map, dropping any stop whose coordinates the operator
  /// has not filled in — or filled in wrongly. A `(0, 0)` stop is the Gulf of
  /// Guinea, and one of those in the list drags the camera off the route
  /// entirely, so it is treated as missing rather than plotted.
  List<MapPinOption> _mapPins(List<RoutePointData> points) {
    return points
        .where((point) => point.hasCoordinates)
        .map(
          (point) => MapPinOption(
            label: point.name,
            subtitle: '',
            x: point.latitude!,
            y: point.longitude!,
          ),
        )
        .toList();
  }
}
