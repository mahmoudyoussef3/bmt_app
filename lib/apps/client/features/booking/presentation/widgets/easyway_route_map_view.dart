import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/map/booking_map_adapters.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/map/route_map_info_panel.dart';
import 'package:bmt_app/core/maps/map_route_stop.dart';
import 'package:bmt_app/core/maps/route_geometry_cache.dart';
import 'package:bmt_app/core/maps/route_geometry_service.dart';
import 'package:bmt_app/core/widgets/maps/animated_route_line.dart';
import 'package:bmt_app/core/widgets/maps/controls/map_control_cluster.dart';
import 'package:bmt_app/core/widgets/maps/easyway_tile_layer.dart';
import 'package:bmt_app/core/widgets/maps/map_camera_animator.dart';
import 'package:bmt_app/core/widgets/maps/markers/callout_marker.dart';
import 'package:bmt_app/core/widgets/maps/markers/station_marker.dart';
import 'package:bmt_app/core/widgets/maps/overlays/map_attribution.dart';
import 'package:bmt_app/core/widgets/maps/overlays/map_empty_panel.dart';
import 'package:bmt_app/core/widgets/maps/overlays/map_legend_pill.dart';
import 'package:bmt_app/core/widgets/maps/simple_vehicle_layer.dart';

export 'package:bmt_app/apps/client/features/booking/presentation/widgets/map/booking_map_adapters.dart'
    show RouteMapInfoData;
export 'package:bmt_app/core/widgets/maps/simple_vehicle_layer.dart'
    show SimpleVehicleData;

/// The EasyWay route map: origin/destination/stop pins, a layered animated
/// route line, real road geometry (OpenRouteService, cached, with a graceful
/// straight-line fallback) and an eased camera that never jumps.
///
/// Used by Route Discovery's map picker, Route Overview's hero map and Route
/// Details — anywhere a passenger previews a route before booking it. Live
/// tracking of a trip in progress uses the richer, GPS-engine-backed map in
/// the tracking feature instead; this widget's [liveVehicle] is for the
/// occasional "nearby captain" pin some of those screens can show.
class EasyWayRouteMapView extends StatefulWidget {
  const EasyWayRouteMapView({
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
  final SimpleVehicleData? liveVehicle;

  @override
  State<EasyWayRouteMapView> createState() => _EasyWayRouteMapViewState();
}

class _EasyWayRouteMapViewState extends State<EasyWayRouteMapView>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  
  late final RouteCameraAnimator _camera;

  List<MapRouteStop> _stops = const [];
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
  void didUpdateWidget(EasyWayRouteMapView oldWidget) {
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
    
    _loadingRoad = _road == null && _stopCoordinates.length > 1;
    if (_loadingRoad) _loadRoadGeometry(_stopCoordinates);
  }

  Future<void> _loadRoadGeometry(List<LatLng> requested) async {
    final road = await RouteGeometryService.instance.load(requested);
    
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
    
    _fitRoute();
  }

  RouteMapInfoData _mergedInfo(BuildContext context) {
    final base = widget.info ?? const RouteMapInfoData();
    final road = _road;
    return RouteMapInfoData(
      distance:
          base.distance ??
          (road != null
              ? formatRouteDistance(context, road.distanceMeters)
              : null),
      duration:
          base.duration ??
          (road != null
              ? formatRouteDuration(context, road.durationSeconds)
              : null),
      status: base.status,
      availableSeats: base.availableSeats,
      passengerCount: base.passengerCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    final stops = _stops;
    if (stops.isEmpty) return const MapEmptyPanel();

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
            const EasyWayTileLayer(),
            if (_stopCoordinates.length > 1)
              AnimatedRouteLine(coordinates: _road?.points ?? _stopCoordinates),
            SimpleVehicleLayer(vehicle: widget.liveVehicle),
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
                markers: [
                  buildCalloutMarker(
                    context,
                    stop: active,
                    index: _activeIndex!,
                    count: stops.length,
                  ),
                ],
              ),
          ],
        ),
        PositionedDirectional(
          top: 12,
          start: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RouteMapInfoPanel(
                stopCount: stops.length,
                info: _mergedInfo(context),
              ),
              if (stops.length > 1) ...[
                const SizedBox(height: 8),
                const MapLegendPill(),
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
              child: MapControlCluster(
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
          child: MapAttribution(showRouting: _road != null),
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
