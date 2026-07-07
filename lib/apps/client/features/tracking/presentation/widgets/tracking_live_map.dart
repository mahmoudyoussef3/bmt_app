import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/core/tracking/tracking.dart';
import 'package:bmt_app/core/widgets/tracking/live_vehicle_layer.dart';
import 'package:bmt_app/core/widgets/tracking/vehicle_track_controller.dart';

import '../../domain/entities/tracking_trip.dart';
import 'tracking_map_overlays.dart';

/// Live tracking map: route polyline, start/end stops, and the vehicle
/// marker animated by the shared tracking engine (interpolation, heading
/// rotation, accuracy circle). The camera follows the vehicle until the
/// rider pans, and a button re-enables following.
class TrackingLiveMap extends StatefulWidget {
  const TrackingLiveMap({
    super.key,
    required this.routePoints,
    required this.vehicleFix,
    required this.currentState,
    required this.onRefresh,
    this.progress,
  });

  final List<TrackingPoint> routePoints;
  final TrackingPoint? vehicleFix;
  final TrackingTripState currentState;
  final VoidCallback onRefresh;

  /// Route progress snapshot: drives the traveled/remaining polyline split
  /// and the per-stop visit-state markers.
  final RouteProgressSnapshot? progress;

  @override
  State<TrackingLiveMap> createState() => _TrackingLiveMapState();
}

class _TrackingLiveMapState extends State<TrackingLiveMap>
    with TickerProviderStateMixin {
  late final VehicleTrackController _track;
  late final AnimationController _pulse;
  final MapController _map = MapController();
  bool _follow = true;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _track = VehicleTrackController(vsync: this);
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _track.addListener(_followVehicle);
    _feedFix();
  }

  @override
  void didUpdateWidget(TrackingLiveMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _feedFix();
  }

  @override
  void dispose() {
    _track.removeListener(_followVehicle);
    _track.dispose();
    _pulse.dispose();
    _map.dispose();
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

  void _followVehicle() {
    if (!_follow || !_mapReady) return;
    final sample = _track.sample;
    if (sample == null) return;
    _map.move(
      LatLng(sample.latitude, sample.longitude),
      _map.camera.zoom,
    );
  }

  List<LatLng> get _route => widget.routePoints
      .where((p) => p.latitude != 0 && p.longitude != 0)
      .map((p) => LatLng(p.latitude, p.longitude))
      .toList();

  /// Splits the route at the traveled distance so the covered part can be
  /// drawn as done and the rest as ahead. Returns (traveled, remaining).
  (List<LatLng>, List<LatLng>) _splitRoute(List<LatLng> route) {
    final traveledMeters = widget.progress?.traveledMeters ?? 0;
    if (route.length < 2 || traveledMeters <= 0) return (const [], route);
    final done = <LatLng>[route.first];
    var covered = 0.0;
    for (var i = 0; i < route.length - 1; i++) {
      final a = route[i];
      final b = route[i + 1];
      final segment = GeoMath.distanceMeters(
        a.latitude,
        a.longitude,
        b.latitude,
        b.longitude,
      );
      if (covered + segment <= traveledMeters) {
        covered += segment;
        done.add(b);
        continue;
      }
      final t = segment == 0 ? 0.0 : (traveledMeters - covered) / segment;
      final cut = LatLng(
        GeoMath.lerpLatitude(a.latitude, b.latitude, t),
        GeoMath.lerpLongitude(a.longitude, b.longitude, t),
      );
      done.add(cut);
      return (done, [cut, ...route.sublist(i + 1)]);
    }
    return (done, const []); // Whole route covered.
  }

  List<Marker> _stopMarkers(List<LatLng> route, BuildContext context) {
    final stops = widget.progress?.stops ?? const <StopProgress>[];
    if (stops.isEmpty) {
      // No progress data: keep the plain origin/destination badges.
      return [
        if (route.isNotEmpty)
          Marker(
            point: route.first,
            width: 44,
            height: 44,
            child: TrackingStopMarker(
              icon: Icons.trip_origin_rounded,
              color: ClientColors.journeyGreen,
            ),
          ),
        if (route.length > 1)
          Marker(
            point: route.last,
            width: 44,
            height: 44,
            child: TrackingStopMarker(
              icon: Icons.location_on_rounded,
              color: Theme.of(context).colorScheme.tertiary,
            ),
          ),
      ];
    }
    return [
      for (final (i, stop) in stops.indexed)
        if (stop.stop.hasCoordinates)
          Marker(
            point: LatLng(stop.stop.latitude, stop.stop.longitude),
            width: 44,
            height: 44,
            child: TrackingProgressStopMarker(
              status: stop.status,
              pulseValue: _pulse.value,
              isDestination: i == stops.length - 1,
            ),
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final route = _route;
    final fix = widget.vehicleFix;
    final vehicle = fix == null ? null : LatLng(fix.latitude, fix.longitude);
    final center = vehicle ?? (route.isNotEmpty ? route.first : null);
    if (center == null) {
      return TrackingNoMapDataPanel(onRefresh: widget.onRefresh);
    }

    final (traveledPath, remainingPath) = _splitRoute(route);
    final boundsPoints = [...route, ?vehicle];
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 13,
              initialCameraFit: boundsPoints.length > 1
                  ? CameraFit.bounds(
                      bounds: LatLngBounds.fromPoints(boundsPoints),
                      padding: const EdgeInsets.all(48),
                    )
                  : null,
              onMapReady: () => _mapReady = true,
              onMapEvent: _handleMapEvent,
              interactionOptions: const InteractionOptions(
                flags:
                    InteractiveFlag.drag |
                    InteractiveFlag.pinchZoom |
                    InteractiveFlag.doubleTapZoom,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.bmt.app',
              ),
              if (route.length > 1)
                PolylineLayer(
                  polylines: [
                    // Covered part of the route reads as done…
                    if (traveledPath.length > 1)
                      Polyline(
                        points: traveledPath,
                        strokeWidth: 5,
                        color: ClientColors.journeyGreen.withAlpha(170),
                      ),
                    // …while the part ahead keeps the brand color.
                    if (remainingPath.length > 1)
                      Polyline(
                        points: remainingPath,
                        strokeWidth: 5,
                        color: ClientColors.primary,
                      ),
                  ],
                ),
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) =>
                    MarkerLayer(markers: _stopMarkers(route, context)),
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
          Positioned(
            right: 12,
            bottom: 64,
            child: _FollowButton(
              active: _follow,
              onPressed: () {
                setState(() => _follow = true);
                _followVehicle();
              },
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: ListenableBuilder(
              listenable: _track,
              builder: (context, _) => TrackingMapStatusStrip(
                sample: _track.sample,
                currentState: widget.currentState,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleMapEvent(MapEvent event) {
    // Any user-driven camera change breaks follow mode; programmatic moves
    // (our own follow calls) must not.
    if (_follow &&
        event.source != MapEventSource.mapController &&
        event.source != MapEventSource.nonRotatedSizeChange &&
        event is MapEventWithMove) {
      setState(() => _follow = false);
    }
  }
}

class _FollowButton extends StatelessWidget {
  const _FollowButton({required this.active, required this.onPressed});

  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active
          ? ClientColors.primary
          : ClientColors.surfaceFor(context).withAlpha(235),
      shape: CircleBorder(
        side: BorderSide(color: ClientColors.borderFor(context)),
      ),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            active ? Icons.my_location_rounded : Icons.location_searching,
            size: 20,
            color: active ? Colors.white : ClientColors.primary,
          ),
        ),
      ),
    );
  }
}
