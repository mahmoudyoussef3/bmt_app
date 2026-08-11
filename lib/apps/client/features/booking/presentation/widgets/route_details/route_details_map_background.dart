import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/easyway_route_map_view.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/no_map_placeholder.dart';
import 'package:bmt_app/core/theme/motion_preference.dart';
import 'package:bmt_app/core/theme/tokens.dart';

/// Full-bleed route map behind the Route Details sheet, with a graceful
/// fallback when no stop on the route has coordinates (spec FR-007).
class RouteDetailsMapBackground extends StatelessWidget {
  const RouteDetailsMapBackground({
    super.key,
    required this.routeId,
    required this.mapPins,
  });

  final String routeId;
  final List<MapPinOption> mapPins;

  @override
  Widget build(BuildContext context) {
    final duration = AppMotion.reduceMotion
        ? Duration.zero
        : AppTokens.motionBase;

    return AnimatedSwitcher(
      duration: duration,
      child: KeyedSubtree(
        key: ValueKey(routeId),
        child: mapPins.isNotEmpty
            ? EasyWayRouteMapView(
                
                waypoints: mapPins,
                cameraPadding: const EdgeInsets.fromLTRB(44, 132, 44, 220),
              )
            : const NoMapPlaceholder(),
      ),
    );
  }
}
