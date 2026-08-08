import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/widgets/client_error_card.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/route_details_map_background.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/route_details_sheet_content.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/route_details_sheet_surface.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/route_details_skeleton.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/route_empty_state.dart';
import 'package:bmt_app/apps/client/features/packages/domain/entities/package_plan.dart';

/// Route Details' body: full-bleed map (with a graceful fallback when no
/// stop has coordinates — spec FR-007) behind a draggable sheet of section
/// cards.
class RouteDetailsBody extends StatelessWidget {
  const RouteDetailsBody({
    super.key,
    required this.isLoading,
    required this.errorMessage,
    required this.routes,
    required this.selectedRoute,
    required this.selectedTripId,
    required this.onRetry,
    required this.onMap,
    required this.onSelectRoute,
    required this.onSelectTrip,
    required this.onSelectPackage,
  });

  final bool isLoading;
  final String? errorMessage;
  final List<RouteOptionData> routes;
  final RouteOptionData? selectedRoute;
  final String? selectedTripId;
  final VoidCallback onRetry;
  final VoidCallback onMap;
  final ValueChanged<RouteOptionData> onSelectRoute;
  final ValueChanged<RouteTripOptionData> onSelectTrip;

  /// Starts the booking with a commute plan already chosen.
  final ValueChanged<PackagePlan> onSelectPackage;

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

    return Stack(
      children: [
        Positioned.fill(
          child: RouteDetailsMapBackground(routeId: route.id, mapPins: mapPins),
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
                onSelectPackage: onSelectPackage,
              ),
            );
          },
        ),
      ],
    );
  }
}
