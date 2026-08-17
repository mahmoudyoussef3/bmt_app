import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/tracking/tracking.dart';
import 'package:bmt_app/core/widgets/maps/map_style.dart';
import 'package:bmt_app/core/widgets/tracking/animated_vehicle_marker.dart';
import 'package:bmt_app/core/widgets/tracking/vehicle_track_controller.dart';

import '../../domain/entities/fleet_feed.dart';
import '../../domain/entities/live_ops_snapshot.dart';
import 'live_ops_format.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';

/// Draws every reporting vehicle in the fleet, interpolated between fixes.
///
/// Until this existed the board drew a static dot per bus and moved it whenever a
/// poll happened to land — so a vehicle covering 200 m in 15 s teleported 200 m,
/// fifteen seconds late. The client app has never done that: it feeds fixes into
/// [VehicleTrackController], which glides the marker between them and rotates it
/// to the smoothed heading. Same engine here, one controller per trip.
///
/// **Why one layer rather than N [LiveVehicleLayer]s.** A marker's position is
/// baked into `Marker.point` at layer-build time, so animating it means rebuilding
/// the layer each frame. One merged listenable rebuilding one `MarkerLayer` costs
/// a single rebuild per frame for the whole fleet; a layer per vehicle would cost
/// N, and stack N `MarkerLayer`s into the map's child list. The ticker inside each
/// controller only runs while that vehicle is actually interpolating, so an idle
/// board costs zero frames.
class FleetVehicleLayer extends StatefulWidget {
  const FleetVehicleLayer({
    super.key,
    required this.trips,
    required this.vehicles,
    required this.now,
    required this.selectedTripId,
    required this.onSelect,
  });

  /// The roster, for labels and overdue flags. Keyed lookup below is by trip id.
  final List<LiveTrip> trips;

  /// Live positions, from the feed Bloc.
  final Map<String, TrackedVehicle> vehicles;

  final DateTime now;
  final String? selectedTripId;
  final ValueChanged<String?> onSelect;

  @override
  State<FleetVehicleLayer> createState() => _FleetVehicleLayerState();
}

class _FleetVehicleLayerState extends State<FleetVehicleLayer>
    with TickerProviderStateMixin {
  /// One track controller per trip, created on that trip's first position and
  /// disposed when it leaves the roster.
  final Map<String, VehicleTrackController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _syncControllers();
  }

  @override
  void didUpdateWidget(covariant FleetVehicleLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncControllers();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    super.dispose();
  }

  /// Feeds new positions in and retires controllers for trips that ended.
  ///
  /// [VehicleTrackController.addFix] is itself the duplicate gate — it runs the
  /// fix through `FixValidator` and returns false for anything not strictly newer
  /// — so re-delivering a position the marker already holds starts no animation.
  void _syncControllers() {
    for (final entry in widget.vehicles.entries) {
      final controller = _controllers.putIfAbsent(
        entry.key,
        () => VehicleTrackController(vsync: this),
      );
      final fix = entry.value.fix;
      controller.addFix(
        VehicleFix(
          latitude: fix.latitude,
          longitude: fix.longitude,
          recordedAt: fix.recordedAt,
          headingDegrees: fix.heading,
          // The entity carries km/h for the desk's labels; the engine wants m/s.
          speedMetersPerSecond: fix.speedKph == null
              ? null
              : fix.speedKph! / 3.6,
        ),
      );
    }

    final gone = _controllers.keys
        .where((id) => !widget.vehicles.containsKey(id))
        .toList();
    for (final id in gone) {
      _controllers.remove(id)?.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controllers.isEmpty) return const SizedBox.shrink();

    final byId = {for (final trip in widget.trips) trip.id: trip};

    return ListenableBuilder(
      // Rebuilds once per frame for the whole fleet, and only while at least one
      // vehicle is mid-interpolation.
      listenable: Listenable.merge(_controllers.values.toList()),
      builder: (context, _) {
        final markers = <Marker>[];

        for (final entry in _controllers.entries) {
          final trip = byId[entry.key];
          final sample = entry.value.sample;
          if (trip == null || sample == null) continue;

          final selected = trip.id == widget.selectedTripId;
          final health =
              widget.vehicles[entry.key]?.healthAt(widget.now) ??
              TrackingHealth.unknown;

          markers.add(
            Marker(
              point: LatLng(sample.latitude, sample.longitude),
              width: selected ? 132 : 52,
              height: selected ? 78 : 52,
              alignment: Alignment.center,
              child: _FleetMarker(
                trip: trip,
                sample: sample,
                health: health,
                selected: selected,
                overdue: trip.isOverdueAt(widget.now),
                onTap: () => widget.onSelect(trip.id),
              ),
            ),
          );
        }

        if (markers.isEmpty) return const SizedBox.shrink();
        return MarkerLayer(markers: markers);
      },
    );
  }
}

class _FleetMarker extends StatelessWidget {
  const _FleetMarker({
    required this.trip,
    required this.sample,
    required this.health,
    required this.selected,
    required this.overdue,
    required this.onTap,
  });

  final LiveTrip trip;
  final VehicleSample sample;
  final TrackingHealth health;
  final bool selected;
  final bool overdue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.status(trackingHealthTone(health));

    return Semantics(
      button: true,
      selected: selected,
      label:
          '${trip.routeName}، التتبّع ${health.label}'
          '${overdue ? '، متأخرة عن الانطلاق' : ''}',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // The shared marker: rotates to the smoothed heading and only
                // shows a direction cone when the vehicle is actually moving.
                AnimatedVehicleMarker(
                  sample: sample,
                  color: colors.ink,
                  size: selected ? 46 : 38,
                ),
                if (selected)
                  IgnorePointer(
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: MapStyle.onSurface(context),
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
                if (overdue)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: MapStyle.surface(context),
                        shape: BoxShape.circle,
                        boxShadow: MapStyle.shadow(context),
                      ),
                      child: Icon(
                        Icons.schedule_rounded,
                        size: 12,
                        color: context.status(AppStatusTone.error).ink,
                      ),
                    ),
                  ),
              ],
            ),
            if (selected) ...[
              const SizedBox(height: 4),
              _MarkerLabel(
                text: trip.vehicleLabel,
                speedKmh: sample.isMoving ? sample.speedKmh : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MarkerLabel extends StatelessWidget {
  const _MarkerLabel({required this.text, this.speedKmh});

  final String text;
  final double? speedKmh;

  @override
  Widget build(BuildContext context) {
    final speed = speedKmh;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: MapStyle.surface(context).withAlpha(242),
        borderRadius: MapStyle.pill,
        border: Border.all(color: MapStyle.border(context)),
        boxShadow: MapStyle.shadow(context),
      ),
      child: Text(
        speed == null ? text : '$text · ${speed.round()} كم/س',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: MapStyle.pillLabel(context),
      ),
    );
  }
}
