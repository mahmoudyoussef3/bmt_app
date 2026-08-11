import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:bmt_app/core/maps/map_route_stop.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/maps/controls/map_control_cluster.dart';
import 'package:bmt_app/core/widgets/maps/easyway_tile_layer.dart';
import 'package:bmt_app/core/widgets/maps/map_camera_animator.dart';
import 'package:bmt_app/core/widgets/maps/markers/station_marker.dart';
import 'package:bmt_app/core/widgets/maps/overlays/map_attribution.dart';
import 'package:bmt_app/core/widgets/maps/route_polyline_layers.dart';

/// A route drawn on the map, read-only.
///
/// The builder used to *be* this map — permanently mounted beside the stop
/// list, armed and disarmed, catching stray clicks. Editing a location now
/// happens in a picker opened on request, which leaves this surface with the
/// one job it is good at: showing the shape of the journey.
///
/// Stops without coordinates are simply absent from it. That is the honest
/// rendering: the map knows where four of six stops are, and says so in
/// [caption] rather than pretending the route is broken.
class RoutePreviewMap extends StatefulWidget {
  final List<MapRouteStop> stops;

  /// Road shape from the directions provider; straight lines between stops are
  /// drawn until (or unless) it arrives.
  final List<LatLng> path;

  /// Stop to centre on when it changes — the timeline row the operator touched.
  final int focusIndex;
  final double height;

  const RoutePreviewMap({
    super.key,
    required this.stops,
    this.path = const [],
    this.focusIndex = -1,
    this.height = 320,
  });

  @override
  State<RoutePreviewMap> createState() => _RoutePreviewMapState();
}

class _RoutePreviewMapState extends State<RoutePreviewMap>
    with SingleTickerProviderStateMixin {
  static const _fallbackCenter = LatLng(30.0444, 31.2357); 

  late final MapController _controller;
  late final RouteCameraAnimator _camera;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = MapController();
    _camera = RouteCameraAnimator(vsync: this, controller: _controller);
  }

  @override
  void didUpdateWidget(RoutePreviewMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_ready) return;

    if (widget.focusIndex != oldWidget.focusIndex) {
      final point = _pointAt(widget.focusIndex);
      if (point != null) {
        _camera.animateTo(
          center: point,
          zoom: _controller.camera.zoom < 13 ? 14 : _controller.camera.zoom,
        );
        return;
      }
    }
    if (_shape(widget.stops) != _shape(oldWidget.stops)) _fit();
  }

  @override
  void dispose() {
    _camera.dispose();
    super.dispose();
  }

  LatLng? _pointAt(int index) {
    if (index < 0 || index >= widget.stops.length) return null;
    return widget.stops[index].coordinate;
  }

  static String _shape(List<MapRouteStop> stops) => stops
      .map((stop) => '${stop.coordinate.latitude},${stop.coordinate.longitude}')
      .join('|');

  void _fit() {
    final points = widget.stops.map((stop) => stop.coordinate).toList();
    if (points.isEmpty) return;
    if (points.length == 1) {
      _camera.animateTo(center: points.first, zoom: 14);
      return;
    }
    _camera.animateFit(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(64),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final points = widget.stops.map((stop) => stop.coordinate).toList();
    final line = widget.path.length >= 2 ? widget.path : points;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.radius),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _controller,
              options: MapOptions(
                initialCenter: points.isEmpty ? _fallbackCenter : points.first,
                initialZoom: points.isEmpty ? 9 : 11,
                minZoom: 4,
                maxZoom: 18,
                onMapReady: () {
                  _ready = true;
                  if (points.length >= 2) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _fit();
                    });
                  }
                },
              ),
              children: [
                const EasyWayTileLayer(),
                if (line.length >= 2)
                  PolylineLayer(polylines: buildRoutePolylines(context, line)),
                MarkerLayer(
                  markers: [
                    for (final entry in widget.stops.indexed)
                      buildStationMarker(
                        context,
                        stop: entry.$2,
                        index: entry.$1,
                        count: widget.stops.length,
                        selected: entry.$1 == widget.focusIndex,
                        onTap: () {},
                      ),
                  ],
                ),
              ],
            ),
            PositionedDirectional(
              bottom: AppSpacing.medium,
              end: AppSpacing.medium,
              child: MapControlCluster(
                onRecenter: _fit,
                onZoomIn: () => _camera.animateZoomBy(1),
                onZoomOut: () => _camera.animateZoomBy(-1),
                recenterTooltip: 'إظهار المسار كاملاً',
                zoomInTooltip: 'تكبير',
                zoomOutTooltip: 'تصغير',
              ),
            ),
            const PositionedDirectional(
              bottom: 4,
              start: 6,
              child: MapAttribution(showRouting: true),
            ),
          ],
        ),
      ),
    );
  }
}
