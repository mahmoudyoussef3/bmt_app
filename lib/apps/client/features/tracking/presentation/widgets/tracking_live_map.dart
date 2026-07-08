import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/core/maps/route_geometry_cache.dart';
import 'package:bmt_app/core/maps/route_geometry_service.dart';
import 'package:bmt_app/core/maps/route_path_math.dart';
import 'package:bmt_app/core/tracking/tracking.dart';
import 'package:bmt_app/core/widgets/maps/controls/map_control_cluster.dart';
import 'package:bmt_app/core/widgets/maps/easyway_tile_layer.dart';
import 'package:bmt_app/core/widgets/maps/map_camera_animator.dart';
import 'package:bmt_app/core/widgets/maps/overlays/map_attribution.dart';
import 'package:bmt_app/core/widgets/maps/overlays/map_empty_panel.dart';
import 'package:bmt_app/core/widgets/maps/route_polyline_layers.dart';
import 'package:bmt_app/core/widgets/tracking/live_vehicle_layer.dart';
import 'package:bmt_app/core/widgets/tracking/vehicle_track_controller.dart';

import '../../domain/entities/tracking_trip.dart';
import 'captain_card.dart';
import 'tracking_map_overlays.dart';

/// Live tracking map, built on the same EasyWay map kit as Route Discovery
/// and Route Details: the shared basemap, a layered traveled/remaining
/// route line over real road geometry (OpenRouteService, cached), an eased
/// camera, and the shared control cluster. The vehicle marker itself is
/// animated by the tracking engine (interpolation, heading rotation,
/// accuracy circle) via [VehicleTrackController]. The camera follows the
/// vehicle until the rider pans, and the control cluster's follow toggle
/// re-enables it.
class TrackingLiveMap extends StatefulWidget {
  const TrackingLiveMap({
    super.key,
    required this.routePoints,
    required this.vehicleFix,
    required this.currentState,
    required this.onRefresh,
    this.progress,
    this.trip,
    this.sheetController,
    this.captainCardTopInset = 12,
  });

  final List<TrackingPoint> routePoints;
  final TrackingPoint? vehicleFix;
  final TrackingTripState currentState;
  final VoidCallback onRefresh;

  /// Top offset for the floating [CaptainCard]. Defaults to a small margin
  /// for layouts where the map isn't behind any app bar chrome (tablet);
  /// callers whose map sits full-bleed behind a transparent, floating app
  /// bar must pass enough inset to clear it.
  final double captainCardTopInset;

  /// Route progress snapshot: drives the traveled/remaining polyline split
  /// and the per-stop visit-state markers.
  final RouteProgressSnapshot? progress;

  /// Feeds the floating [CaptainCard]; omitted when unavailable.
  final TrackingTripData? trip;

  /// The bottom sheet covering part of the map on phones. When attached,
  /// its current extent pads the camera fit so the route/vehicle never
  /// settle behind it.
  final DraggableScrollableController? sheetController;

  @override
  State<TrackingLiveMap> createState() => _TrackingLiveMapState();
}

class _TrackingLiveMapState extends State<TrackingLiveMap>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  // Created in initState: a lazy `late final` ticker would otherwise be
  // instantiated during dispose() when no build path ever touched it.
  late final RouteCameraAnimator _camera;
  late final VehicleTrackController _track;
  late final AnimationController _pulse;

  List<LatLng> _stopCoordinates = const [];
  RoadRoute? _road;
  bool _loadingRoad = false;
  bool _mapReady = false;
  bool _follow = true;

  @override
  void initState() {
    super.initState();
    _camera = RouteCameraAnimator(vsync: this, controller: _mapController);
    _track = VehicleTrackController(vsync: this);
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _track.addListener(_followVehicle);
    _feedFix();
    _syncRoute();
  }

  @override
  void didUpdateWidget(TrackingLiveMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _feedFix();
    final previous = RouteGeometryCache.signatureFor(_stopCoordinates);
    _syncRoute();
    if (_mapReady &&
        previous != RouteGeometryCache.signatureFor(_stopCoordinates)) {
      _fitRoute();
    }
  }

  @override
  void dispose() {
    _track.removeListener(_followVehicle);
    _track.dispose();
    _pulse.dispose();
    _camera.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _feedFix() {
    final fix = widget.vehicleFix;
    if (fix == null) return;
    _track.addFix(
      VehicleFix(
        latitude: fix.latitude,
        longitude: fix.longitude,
        recordedAt: fix.recordedAt ?? DateTime.now(),
        headingDegrees: fix.heading,
        speedMetersPerSecond: fix.speed,
        accuracyMeters: fix.accuracy,
      ),
    );
  }

  /// Recomputes the stop coordinates and kicks off (or reuses) the road
  /// geometry lookup. Cached geometry applies synchronously so a previously
  /// viewed trip renders roads on its very first frame.
  void _syncRoute() {
    _stopCoordinates = widget.routePoints
        .where((p) => p.latitude != 0 && p.longitude != 0)
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList(growable: false);

    _road = RouteGeometryService.instance.cached(_stopCoordinates);
    _loadingRoad = _road == null && _stopCoordinates.length > 1;
    if (_loadingRoad) _loadRoadGeometry(_stopCoordinates);
  }

  Future<void> _loadRoadGeometry(List<LatLng> requested) async {
    final road = await RouteGeometryService.instance.load(requested);
    // Ignore stale responses: the trip may have changed mid-flight.
    if (!mounted || !identical(requested, _stopCoordinates)) return;
    setState(() {
      _loadingRoad = false;
      _road = road;
    });
    if (road != null && _mapReady) _fitRoute();
  }

  /// The path actually drawn: road geometry when available, otherwise the
  /// straight stop-to-stop fallback.
  List<LatLng> get _route => _road?.points ?? _stopCoordinates;

  void _followVehicle() {
    if (!_follow || !_mapReady) return;
    final sample = _track.sample;
    if (sample == null) return;
    _camera.animateTo(
      center: LatLng(sample.latitude, sample.longitude),
      zoom: _mapController.camera.zoom,
    );
  }

  /// Height of the draggable sheet currently covering the map, in pixels —
  /// 0 when there is no sheet or it hasn't attached yet.
  double get _sheetInsetPixels {
    final controller = widget.sheetController;
    if (controller == null || !controller.isAttached) return 0;
    return controller.size * MediaQuery.sizeOf(context).height;
  }

  CameraFit? _cameraFit() {
    final fix = widget.vehicleFix;
    final points = [
      ..._route,
      if (fix != null) LatLng(fix.latitude, fix.longitude),
    ];
    if (points.length < 2) return null;
    return CameraFit.bounds(
      bounds: LatLngBounds.fromPoints(points),
      padding: EdgeInsets.fromLTRB(48, 48, 48, 48 + _sheetInsetPixels),
      maxZoom: 16,
    );
  }

  void _fitRoute() {
    final fit = _cameraFit();
    if (fit != null) {
      _camera.animateFit(fit);
    } else if (_route.isNotEmpty) {
      _camera.animateTo(center: _route.first, zoom: 14);
    }
  }

  void _onMapReady() {
    _mapReady = true;
  }

  /// Splits the drawn path at the progress engine's route fraction so the
  /// covered part reads as done and the rest as ahead. The fraction (not an
  /// absolute meters value) is what's safe to reuse here: the engine
  /// measures progress over the straight stop-to-stop distance, which is
  /// shorter than this road-following path.
  (List<LatLng>, List<LatLng>) _splitRoute(List<LatLng> route) {
    final fraction = widget.progress?.routeFraction ?? 0;
    if (route.length < 2 || fraction <= 0) return (const [], route);
    final cumulative = RoutePathMath.cumulativeDistances(route);
    return RoutePathMath.splitAtFraction(route, cumulative, fraction);
  }

  @override
  Widget build(BuildContext context) {
    final route = _route;
    final fix = widget.vehicleFix;
    final vehicle = fix == null ? null : LatLng(fix.latitude, fix.longitude);
    final center = vehicle ?? (route.isNotEmpty ? route.first : null);
    if (center == null) {
      return MapEmptyPanel(
        title: 'Map data unavailable',
        message: 'No route coordinates were found for this trip.',
        onRetry: widget.onRefresh,
      );
    }

    final (traveledPath, remainingPath) = _splitRoute(route);
    final trip = widget.trip;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 13,
              initialCameraFit: _cameraFit(),
              onMapReady: _onMapReady,
              onMapEvent: _handleMapEvent,
              interactionOptions: const InteractionOptions(
                flags:
                    InteractiveFlag.drag |
                    InteractiveFlag.pinchZoom |
                    InteractiveFlag.doubleTapZoom,
              ),
            ),
            children: [
              const EasyWayTileLayer(),
              if (route.length > 1)
                PolylineLayer(
                  polylines: [
                    // Covered part of the route reads as done…
                    ...buildRoutePolylines(
                      context,
                      traveledPath,
                      color: ClientColors.journeyGreen,
                      glow: false,
                    ),
                    // …while the part ahead keeps the brand color and glow.
                    ...buildRoutePolylines(context, remainingPath),
                  ],
                ),
              MarkerLayer(
                markers: buildTrackingStopMarkers(
                  context,
                  route: route,
                  stops: widget.progress?.stops ?? const <StopProgress>[],
                ),
              ),
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) => LiveVehicleLayer(
                  controller: _track,
                  color: ClientColors.primary,
                  pulseValue: _pulse.value,
                ),
              ),
            ],
          ),
          if (trip != null)
            PositionedDirectional(
              top: widget.captainCardTopInset,
              start: 12,
              child: CaptainCard(
                driverInitials: trip.driverInitials,
                driverName: trip.displayDriverName,
                vehiclePlate: trip.displayVehiclePlate,
                currentState: widget.currentState,
                driverRating: trip.driverRating,
                sample: _track.sample,
              ),
            ),
          PositionedDirectional(
            top: 0,
            bottom: 0,
            end: 12,
            child: Align(
              alignment: const Alignment(0, -0.15),
              child: MapControlCluster(
                onRecenter: _fitRoute,
                onZoomIn: () => _camera.animateZoomBy(1),
                onZoomOut: () => _camera.animateZoomBy(-1),
                onToggleFollow: () {
                  setState(() => _follow = true);
                  _followVehicle();
                },
                followActive: _follow,
              ),
            ),
          ),
          PositionedDirectional(
            end: 6,
            bottom: 6,
            child: MapAttribution(showRouting: _road != null),
          ),
        ],
      ),
    );
  }

  void _handleMapEvent(MapEvent event) {
    // Any user-driven camera change breaks follow mode; programmatic moves
    // (our own follow/fit calls) must not.
    if (_follow &&
        event.source != MapEventSource.mapController &&
        event.source != MapEventSource.nonRotatedSizeChange &&
        event is MapEventWithMove) {
      setState(() => _follow = false);
    }
  }
}
