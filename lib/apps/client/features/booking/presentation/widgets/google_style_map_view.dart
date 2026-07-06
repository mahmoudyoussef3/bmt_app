import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/map/animated_route_line.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/map/live_vehicle_layer.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/map/route_camera_controller.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/map/route_geometry_cache.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/map/route_geometry_service.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/map/route_map_info_panel.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/map/route_map_layers.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/map/route_map_markers.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/map/route_map_models.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/map/route_map_overlays.dart';

export 'package:bmt_app/apps/client/features/booking/presentation/widgets/map/live_vehicle_layer.dart'
    show LiveVehicleData;
export 'package:bmt_app/apps/client/features/booking/presentation/widgets/map/route_map_models.dart'
    show RouteMapInfoData;

/// A route map backed by a clean, theme-aware basemap.
///
/// The route follows real roads (OpenRouteService geometry, cached and drawn
/// with a progressive reveal) and gracefully falls back to straight lines when
/// geometry is unavailable. The camera animates: it settles onto the route on
/// open, refits smoothly when stops or padding change, and never jumps.
/// Invalid coordinates are ignored so the UI never renders a plausible-looking
/// marker for data that does not exist. Stops are tappable to reveal their
/// name, and an optional [liveVehicle] renders a smoothly interpolated
/// captain position.
class GoogleStyleMapView extends StatefulWidget {
  const GoogleStyleMapView({
    super.key,
    this.pickup,
    this.destination,
    this.waypoints = const [],
    this.cameraPadding = const EdgeInsets.all(48),
    this.interactive = true,
    this.info,
    this.liveVehicle,
  });

  final MapPinOption? pickup;
  final MapPinOption? destination;
  final List<MapPinOption> waypoints;
  final EdgeInsets cameraPadding;
  final bool interactive;

  /// Optional trip facts for the info overlay; road-derived distance/duration
  /// fill any gaps once geometry loads.
  final RouteMapInfoData? info;

  /// Optional live captain position. Nothing renders when null.
  final LiveVehicleData? liveVehicle;

  @override
  State<GoogleStyleMapView> createState() => _GoogleStyleMapViewState();
}

class _GoogleStyleMapViewState extends State<GoogleStyleMapView>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  // Created in initState: a lazy `late final` ticker would otherwise be
  // instantiated during dispose() when no build path ever touched it.
  late final RouteCameraAnimator _camera;

  List<RouteMapStop> _stops = const [];
  List<LatLng> _stopCoordinates = const [];
  RoadRoute? _road;
  bool _loadingRoad = false;
  bool _mapReady = false;
  int? _activeIndex;

  @override
  void initState() {
    super.initState();
    _camera = RouteCameraAnimator(vsync: this, controller: _mapController);
    _syncStops();
  }

  @override
  void didUpdateWidget(GoogleStyleMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous = RouteGeometryCache.signatureFor(_stopCoordinates);
    _syncStops();
    final changed =
        previous != RouteGeometryCache.signatureFor(_stopCoordinates);
    if (changed) _activeIndex = null;
    if (_mapReady &&
        (changed || oldWidget.cameraPadding != widget.cameraPadding)) {
      _fitRoute();
    }
  }

  @override
  void dispose() {
    _camera.dispose();
    _mapController.dispose();
    super.dispose();
  }

  /// Recomputes stops from the widget's pins and kicks off (or reuses) the
  /// road geometry lookup. Cached geometry applies synchronously so a
  /// previously viewed route renders roads on its very first frame.
  void _syncStops() {
    final pins = widget.waypoints.isNotEmpty
        ? widget.waypoints
        : <MapPinOption>[?widget.pickup, ?widget.destination];
    _stops = routeMapStopsFromPins(pins);
    _stopCoordinates = _stops
        .map((stop) => stop.coordinate)
        .toList(growable: false);

    _road = RouteGeometryService.instance.cached(_stopCoordinates);
    // No setState here: _syncStops only runs from initState/didUpdateWidget,
    // both of which are followed by a build.
    _loadingRoad = _road == null && _stopCoordinates.length > 1;
    if (_loadingRoad) _loadRoadGeometry(_stopCoordinates);
  }

  Future<void> _loadRoadGeometry(List<LatLng> requested) async {
    final road = await RouteGeometryService.instance.load(requested);
    // Ignore stale responses: the stops may have changed mid-flight.
    if (!mounted || !identical(requested, _stopCoordinates)) return;
    setState(() {
      _loadingRoad = false;
      _road = road;
    });
    if (road != null && _mapReady) _fitRoute();
  }

  /// Points the camera must keep visible: the road shape when we have it
  /// (it can bulge beyond the stop bounds), otherwise the stops.
  List<LatLng> get _fitPoints => _road?.points ?? _stopCoordinates;

  CameraFit? _cameraFit({double extraPadding = 0}) {
    final points = _fitPoints;
    if (points.length < 2) return null;
    final padding = widget.cameraPadding;
    return CameraFit.bounds(
      bounds: LatLngBounds.fromPoints(points),
      padding: EdgeInsets.fromLTRB(
        padding.left + extraPadding,
        padding.top + extraPadding,
        padding.right + extraPadding,
        padding.bottom + extraPadding,
      ),
      maxZoom: 15,
    );
  }

  void _fitRoute() {
    final fit = _cameraFit();
    if (fit != null) {
      _camera.animateFit(fit);
    } else if (_stopCoordinates.isNotEmpty) {
      _camera.animateTo(center: _stopCoordinates.first, zoom: 15);
    }
  }

  void _onMapReady() {
    _mapReady = true;
    // Entrance: the initial camera sits slightly wide; settle onto the route.
    _fitRoute();
  }

  RouteMapInfoData get _mergedInfo {
    final base = widget.info ?? const RouteMapInfoData();
    final road = _road;
    return RouteMapInfoData(
      distance:
          base.distance ??
          (road != null ? formatRouteDistance(road.distanceMeters) : null),
      duration:
          base.duration ??
          (road != null ? formatRouteDuration(road.durationSeconds) : null),
      status: base.status,
      availableSeats: base.availableSeats,
      passengerCount: base.passengerCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    final stops = _stops;
    if (stops.isEmpty) return const RouteMapEmptyPanel();

    final active = _activeIndex != null && _activeIndex! < stops.length
        ? stops[_activeIndex!]
        : null;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _centerFor(_stopCoordinates),
            initialZoom: 13,
            initialCameraFit: _cameraFit(extraPadding: 56),
            minZoom: 5,
            maxZoom: 18,
            onMapReady: _onMapReady,
            onTap: (_, _) => _dismissCallout(),
            interactionOptions: InteractionOptions(
              flags: widget.interactive
                  ? InteractiveFlag.drag |
                        InteractiveFlag.pinchZoom |
                        InteractiveFlag.doubleTapZoom |
                        InteractiveFlag.flingAnimation
                  : InteractiveFlag.none,
            ),
          ),
          children: [
            const RouteMapTileLayer(),
            if (_stopCoordinates.length > 1)
              AnimatedRouteLine(
                coordinates: _road?.points ?? _stopCoordinates,
              ),
            LiveVehicleLayer(vehicle: widget.liveVehicle),
            MarkerLayer(
              markers: [
                for (final entry in stops.indexed)
                  buildStationMarker(
                    context,
                    stop: entry.$2,
                    index: entry.$1,
                    count: stops.length,
                    selected: entry.$1 == _activeIndex,
                    onTap: () => _toggleCallout(entry.$1),
                  ),
              ],
            ),
            if (active != null)
              MarkerLayer(
                markers: [buildCalloutMarker(context, stop: active)],
              ),
          ],
        ),
        PositionedDirectional(
          top: 12,
          start: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RouteMapInfoPanel(stopCount: stops.length, info: _mergedInfo),
              if (stops.length > 1) ...[
                const SizedBox(height: 8),
                const RouteMapLegendPill(),
              ],
              if (_loadingRoad) ...[
                const SizedBox(height: 8),
                const RouteMapLoadingPill(),
              ],
            ],
          ),
        ),
        if (widget.interactive)
          PositionedDirectional(
            top: 0,
            bottom: 0,
            end: 12,
            child: Align(
              alignment: const Alignment(0, -0.15),
              child: RouteMapControls(
                onRecenter: () {
                  _dismissCallout();
                  _fitRoute();
                },
                onZoomIn: () => _camera.animateZoomBy(1),
                onZoomOut: () => _camera.animateZoomBy(-1),
              ),
            ),
          ),
        PositionedDirectional(
          end: 6,
          bottom: 6,
          child: RouteMapAttribution(showRouting: _road != null),
        ),
      ],
    );
  }

  void _toggleCallout(int index) {
    setState(() => _activeIndex = _activeIndex == index ? null : index);
  }

  void _dismissCallout() {
    if (_activeIndex != null) setState(() => _activeIndex = null);
  }

  LatLng _centerFor(List<LatLng> points) {
    final lat = points.map((point) => point.latitude).reduce((a, b) => a + b);
    final lng = points.map((point) => point.longitude).reduce((a, b) => a + b);
    return LatLng(lat / points.length, lng / points.length);
  }
}
