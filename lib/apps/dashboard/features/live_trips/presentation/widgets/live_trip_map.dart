import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/tracking/tracking.dart';
import 'package:bmt_app/core/widgets/tracking/live_vehicle_layer.dart';
import 'package:bmt_app/core/widgets/tracking/vehicle_track_controller.dart';

import '../../domain/entities/live_trip.dart';

/// Operations map for a live trip: route line, stop status dots, and the
/// vehicle marker driven by the shared tracking engine (smooth movement,
/// heading rotation, GPS accuracy circle, staleness styling).
class LiveTripMap extends StatefulWidget {
  const LiveTripMap({super.key, required this.trip});

  final LiveTrip trip;

  @override
  State<LiveTripMap> createState() => _LiveTripMapState();
}

class _LiveTripMapState extends State<LiveTripMap>
    with TickerProviderStateMixin {
  late final VehicleTrackController _track;

  @override
  void initState() {
    super.initState();
    _track = VehicleTrackController(vsync: this);
    _feedFix();
  }

  @override
  void didUpdateWidget(LiveTripMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trip.id != widget.trip.id) _track.reset();
    _feedFix();
  }

  @override
  void dispose() {
    _track.dispose();
    super.dispose();
  }

  void _feedFix() {
    final position = widget.trip.vehiclePosition;
    if (position == null) return;
    _track.addFix(
      VehicleFix(
        latitude: position.latitude,
        longitude: position.longitude,
        recordedAt: position.updatedAt,
        headingDegrees: position.heading,
        speedMetersPerSecond: position.speed,
        accuracyMeters: position.accuracy,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final points = widget.trip.routePoints;
    final latlngs = points.map((p) => LatLng(p.latitude, p.longitude)).toList();
    final currentIdx = points
        .indexWhere((p) => p.status == LivePointStatus.current)
        .clamp(0, latlngs.length - 1);
    final position = widget.trip.vehiclePosition;
    final center = position != null
        ? LatLng(position.latitude, position.longitude)
        : latlngs[currentIdx];

    return FlutterMap(
      options: MapOptions(initialCenter: center, initialZoom: 12),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.bmt.app',
        ),
        PolylineLayer(
          polylines: [
            Polyline(points: latlngs, color: scheme.primary, strokeWidth: 3),
          ],
        ),
        MarkerLayer(
          markers: [
            for (final p in points)
              Marker(
                point: LatLng(p.latitude, p.longitude),
                child: _StopDot(status: p.status),
              ),
          ],
        ),
        LiveVehicleLayer(
          controller: _track,
          color: scheme.primary,
          label: widget.trip.vehiclePlate,
          markerSize: 44,
        ),
      ],
    );
  }
}

class _StopDot extends StatelessWidget {
  const _StopDot({required this.status});
  final LivePointStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      LivePointStatus.completed => AppStatusColors.onSuccessContainer,
      LivePointStatus.current => AppStatusColors.onInfoContainer,
      LivePointStatus.arrived => AppStatusColors.onSpecialContainer,
      LivePointStatus.skipped => AppStatusColors.onNeutralContainer,
      LivePointStatus.pending => AppStatusColors.onWarningContainer,
    };
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [BoxShadow(color: color.withAlpha(100), blurRadius: 4)],
      ),
    );
  }
}
