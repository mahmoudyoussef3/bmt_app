import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/utils/open_in_maps.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/easyway_route_map_view.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/no_map_placeholder.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/route_stop_timeline.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/stop_schedule_labels.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/theme/app_layout.dart';

/// This line, full screen: **every** station plotted on the map, and the same
/// stations listed underneath with the hour the bus is expected at each and a
/// way to open any of them in a maps app.
///
/// Route Details' map card used to open the stop *picker* — a screen for
/// changing what you searched for, reached by tapping a picture of the line
/// you had already found. And the picker plots two pins, origin and
/// destination, so a rider who tapped a line with nine stations to see where
/// it goes was shown the two places they already knew.
///
/// The map keeps the top of the screen and the list the bottom, rather than
/// floating a draggable sheet over the map: with a sheet, every vertical drag
/// is ambiguous between panning the map and moving the sheet.
class RouteMapScreen extends StatelessWidget {
  const RouteMapScreen({super.key, required this.route});

  final RouteOptionData route;

  /// Placeholders the operator's record uses for a fact nobody has filled in.
  /// Passed through to the map's info panel they would print literally, so
  /// they resolve to null and let the road geometry answer instead.
  static const _unsetFacts = {'', 'Not set', 'N/A'};

  @override
  Widget build(BuildContext context) {
    final orderedPoints = [...route.points]
      ..sort((a, b) => a.order.compareTo(b.order));
    final mapPins = orderedPoints
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

    return Scaffold(
      backgroundColor: ClientColors.backgroundFor(context),
      appBar: ClientAppBar(
        title: context.l10n.booking_routeMapTitle,
        subtitle: route.routeName,
      ),
      body: Column(
        children: [
          _MapPane(route: route, mapPins: mapPins, unsetFacts: _unsetFacts),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: AppLayout.maxContentWidth(
                    MediaQuery.sizeOf(context).width,
                  ),
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    RouteStopTimeline(
                      points: orderedPoints,
                      referenceDeparture: referenceDepartureOf(
                        route.availableTrips,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The map itself, given a fixed share of the screen so the station list keeps
/// a usable half on a short phone.
class _MapPane extends StatelessWidget {
  const _MapPane({
    required this.route,
    required this.mapPins,
    required this.unsetFacts,
  });

  final RouteOptionData route;
  final List<MapPinOption> mapPins;
  final Set<String> unsetFacts;

  @override
  Widget build(BuildContext context) {
    final height = (MediaQuery.sizeOf(context).height * 0.42).clamp(
      220.0,
      380.0,
    );

    return SizedBox(
      height: height,
      child: mapPins.isEmpty
          ? const NoMapPlaceholder()
          : EasyWayRouteMapView(
              waypoints: mapPins,
              cameraPadding: const EdgeInsets.fromLTRB(40, 96, 40, 40),
              info: RouteMapInfoData(
                distance: _fact(route.distance),
                duration: _fact(route.duration),
                availableSeats: route.availableSeats,
              ),
              directionsLabel: context.l10n.booking_openInMaps,
              onStopDirections: (stop) => openCoordinatesInMaps(
                context,
                latitude: stop.coordinate.latitude,
                longitude: stop.coordinate.longitude,
                label: stop.name,
              ),
            ),
    );
  }

  String? _fact(String value) =>
      unsetFacts.contains(value.trim()) ? null : value;
}
