import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/widgets/client_error_card.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_state.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/easyway_route_map_view.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/no_map_placeholder.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/route_details_sheet_content.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/route_details_sheet_surface.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/route_details_skeleton.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/route_empty_state.dart';
import 'package:bmt_app/core/theme/motion_preference.dart';
import 'package:bmt_app/core/theme/tokens.dart';

/// Route Details' body: full-bleed map (with a graceful fallback when no
/// stop has coordinates — spec FR-007) behind a draggable sheet of section
/// cards, sized to whichever [BookingState] arrives.
class RouteDetailsBody extends StatelessWidget {
  const RouteDetailsBody({
    super.key,
    required this.state,
    required this.routes,
    required this.selectedRoute,
    required this.selectedTripId,
    required this.onRetry,
    required this.onMap,
    required this.onSelectRoute,
    required this.onSelectTrip,
  });

  final BookingState state;
  final List<RouteOptionData> routes;
  final RouteOptionData? selectedRoute;
  final String? selectedTripId;
  final VoidCallback onRetry;
  final VoidCallback onMap;
  final ValueChanged<RouteOptionData> onSelectRoute;
  final ValueChanged<RouteTripOptionData> onSelectTrip;

  @override
  Widget build(BuildContext context) {
    if (state is BookingLoading) return const RouteDetailsSkeleton();
    if (state is BookingError) {
      return ClientErrorCard.fullScreen(
        message: (state as BookingError).message,
        onRetry: onRetry,
      );
    }
    final route = selectedRoute;
    if (route == null) return RouteEmptyState(onRetry: onRetry);

    final orderedPoints = [...route.points]
      ..sort((a, b) => a.order.compareTo(b.order));
    final mapPins = orderedPoints
        .where((p) => p.latitude != null && p.longitude != null)
        .map(
          (p) => MapPinOption(
            label: p.name,
            subtitle: '',
            x: p.latitude!,
            y: p.longitude!,
          ),
        )
        .toList();

    final mapDuration = AppMotion.reduceMotion
        ? Duration.zero
        : AppTokens.motionBase;

    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: mapDuration,
            child: KeyedSubtree(
              key: ValueKey(route.id),
              child: mapPins.isNotEmpty
                  ? EasyWayRouteMapView(
                      waypoints: mapPins,
                      cameraPadding: const EdgeInsets.fromLTRB(44, 54, 44, 220),
                    )
                  : const NoMapPlaceholder(),
            ),
          ),
        ),
        DraggableScrollableSheet(
          initialChildSize: 0.48,
          minChildSize: 0.30,
          maxChildSize: 0.96,
          snap: true,
          snapSizes: const [0.30, 0.48, 0.96],
          // Not wrapped in AnimatedSwitcher: this ListView shares a single
          // ScrollController with DraggableScrollableSheet, and keeping two
          // copies mounted mid-crossfade would attach that controller to two
          // Scrollables at once and crash.
          builder: (context, scrollController) {
            return RouteDetailsSheetSurface(
              child: RouteDetailsSheetContent(
                key: ValueKey(route.id),
                scrollController: scrollController,
                route: route,
                routes: routes,
                orderedPoints: orderedPoints,
                selectedTripId: selectedTripId,
                onMap: onMap,
                onSelectRoute: onSelectRoute,
                onSelectTrip: onSelectTrip,
              ),
            );
          },
        ),
      ],
    );
  }
}
