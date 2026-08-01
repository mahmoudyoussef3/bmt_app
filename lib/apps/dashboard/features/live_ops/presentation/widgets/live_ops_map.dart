import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/maps/easyway_tile_layer.dart';
import 'package:bmt_app/core/widgets/maps/map_camera_animator.dart';
import 'package:bmt_app/core/widgets/maps/map_style.dart';

import '../../domain/entities/live_ops_snapshot.dart';
import 'live_ops_format.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';

/// The operations desk's fleet map: every active trip that has reported a
/// position, drawn at once, coloured by tracking health.
///
/// This is the "understand the situation in seconds" surface. It answers three
/// questions without a click — where is the fleet, which vehicles are actually
/// reporting, and is anything bunched or stranded — and defers detail to the
/// trip cards beside it. Tapping a vehicle selects its trip (and tapping the
/// selected one again clears the focus), which is the same selection the card
/// list highlights, so map and list are always one shared idea of "current".
///
/// Trips with no fix are deliberately absent: drawing them at a guessed
/// location would be a lie, and they remain fully visible in the trip list with
/// their tracking marked unknown.
class LiveOpsMap extends StatefulWidget {
  const LiveOpsMap({
    super.key,
    required this.trips,
    required this.now,
    required this.selectedTripId,
    required this.onSelect,
    this.height = 420,
  });

  final List<LiveTrip> trips;
  final DateTime now;
  final String? selectedTripId;
  final ValueChanged<String?> onSelect;
  final double height;

  @override
  State<LiveOpsMap> createState() => _LiveOpsMapState();
}

class _LiveOpsMapState extends State<LiveOpsMap>
    with SingleTickerProviderStateMixin {
  final MapController _controller = MapController();
  RouteCameraAnimator? _camera;

  /// Set once the map reports ready. Moving the camera before that throws in
  /// flutter_map, so every camera call is gated on it.
  bool _ready = false;

  /// Which trips were on screen at the last fit, so the camera re-fits when the
  /// fleet composition changes but not on every 15s position nudge — a map that
  /// re-frames itself twice a minute is unusable for watching.
  String _lastFitSignature = '';

  /// Cairo, as a neutral opening frame for the moment before any fix exists.
  static const _fallbackCenter = LatLng(30.0444, 31.2357);
  static const _selectedZoom = 13.5;

  @override
  void initState() {
    super.initState();
    _camera = RouteCameraAnimator(vsync: this, controller: _controller);
  }

  @override
  void dispose() {
    _camera?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant LiveOpsMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_ready) return;

    if (widget.selectedTripId != oldWidget.selectedTripId) {
      _applySelection();
      return;
    }
    if (_signature != _lastFitSignature) _fitAll();
  }

  /// Identity of the current fleet on the map. Position is excluded on purpose
  /// (see [_lastFitSignature]).
  String get _signature => widget.trips.map((t) => t.id).toList().join(',');

  List<LiveTrip> get _mappable =>
      widget.trips.where((t) => t.lastFix != null).toList();

  void _onReady() {
    _ready = true;
    // Fitting inside the ready callback is a frame too early for flutter_map to
    // have a sized camera; one post-frame hop makes the first fit land.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.selectedTripId != null ? _applySelection() : _fitAll();
    });
  }

  void _applySelection() {
    final id = widget.selectedTripId;
    if (id == null) {
      _fitAll();
      return;
    }
    LiveTrip? target;
    for (final trip in _mappable) {
      if (trip.id == id) target = trip;
    }
    final fix = target?.lastFix;
    if (fix == null) {
      // Selected a trip with no position: keep the wide view rather than
      // flying somewhere arbitrary.
      _fitAll();
      return;
    }
    _camera?.animateTo(
      center: LatLng(fix.latitude, fix.longitude),
      zoom: _selectedZoom,
    );
  }

  void _fitAll() {
    _lastFitSignature = _signature;
    final points = [
      for (final trip in _mappable)
        LatLng(trip.lastFix!.latitude, trip.lastFix!.longitude),
    ];
    if (points.isEmpty) return;

    if (points.length == 1) {
      _camera?.animateTo(center: points.first, zoom: 12.5);
      return;
    }
    _camera?.animateFit(
      CameraFit.coordinates(
        coordinates: points,
        padding: const EdgeInsets.all(56),
        maxZoom: 14,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mappable = _mappable;
    final untracked = widget.trips.length - mappable.length;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.radius),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: FlutterMap(
                  mapController: _controller,
                  options: MapOptions(
                    initialCenter: mappable.isEmpty
                        ? _fallbackCenter
                        : LatLng(
                            mappable.first.lastFix!.latitude,
                            mappable.first.lastFix!.longitude,
                          ),
                    initialZoom: 11,
                    onMapReady: _onReady,
                    // Tapping empty map clears the focus — the same gesture
                    // users expect from every mapping tool.
                    onTap: (_, _) => widget.onSelect(null),
                    interactionOptions: const InteractionOptions(
                      flags:
                          InteractiveFlag.drag |
                          InteractiveFlag.pinchZoom |
                          InteractiveFlag.doubleTapZoom |
                          InteractiveFlag.scrollWheelZoom,
                    ),
                  ),
                  children: [
                    const EasyWayTileLayer(),
                    MarkerLayer(
                      markers: [
                        for (final trip in mappable)
                          _vehicleMarker(
                            trip,
                            selected: trip.id == widget.selectedTripId,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (mappable.isEmpty)
              const Positioned.fill(child: _NoPositionsOverlay()),
            Positioned(
              top: AppSpacing.small,
              left: AppSpacing.small,
              right: AppSpacing.small,
              child: _MapLegend(untracked: untracked),
            ),
          ],
        ),
      ),
    );
  }

  Marker _vehicleMarker(LiveTrip trip, {required bool selected}) {
    final fix = trip.lastFix!;
    final health = trip.trackingHealthAt(widget.now);
    // A selected marker needs room for its label; sizing every marker for the
    // widest case would make a busy map unreadable.
    final size = selected ? 132.0 : 44.0;

    return Marker(
      point: LatLng(fix.latitude, fix.longitude),
      width: size,
      height: selected ? 74 : 44,
      alignment: Alignment.center,
      child: _VehicleMarker(
        trip: trip,
        health: health,
        selected: selected,
        overdue: trip.isOverdueAt(widget.now),
        onTap: () => widget.onSelect(trip.id),
      ),
    );
  }
}

class _VehicleMarker extends StatelessWidget {
  const _VehicleMarker({
    required this.trip,
    required this.health,
    required this.selected,
    required this.overdue,
    required this.onTap,
  });

  final LiveTrip trip;
  final TrackingHealth health;
  final bool selected;
  final bool overdue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardChartPalette.of(context);
    final colors = context.status(trackingHealthTone(health));

    final dot = Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: colors.tint,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? MapStyle.onSurface(context) : colors.ink,
          width: selected ? 3 : 2,
        ),
        boxShadow: MapStyle.shadow(context),
      ),
      child: Icon(Icons.directions_bus_rounded, size: 18, color: colors.ink),
    );

    return Semantics(
      button: true,
      // The marker's meaning must survive without colour vision: route, health
      // and lateness are all spoken.
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
                dot,
                if (overdue)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.schedule_rounded,
                        size: 12,
                        color: palette.negative,
                      ),
                    ),
                  ),
              ],
            ),
            if (selected) ...[
              const SizedBox(height: 4),
              _MarkerLabel(text: trip.vehicleLabel),
            ],
          ],
        ),
      ),
    );
  }
}

class _MarkerLabel extends StatelessWidget {
  const _MarkerLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: MapStyle.surface(context).withAlpha(242),
        borderRadius: MapStyle.pill,
        border: Border.all(color: MapStyle.border(context)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: MapStyle.pillLabel(context),
      ),
    );
  }
}

/// Health key plus an honest count of trips the map cannot place. Without that
/// count, an operator seeing three buses would assume three trips are running.
class _MapLegend extends StatelessWidget {
  const _MapLegend({required this.untracked});

  final int untracked;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: MapStyle.surface(context).withAlpha(240),
          borderRadius: MapStyle.pill,
          border: Border.all(color: MapStyle.border(context)),
          boxShadow: MapStyle.shadow(context),
        ),
        // Wrap, not Row: at large text scales or a narrow panel the key must
        // stack instead of overflowing the map.
        child: Wrap(
          spacing: 10,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final health in TrackingHealth.values)
              _LegendEntry(health: health),
            if (untracked > 0)
              Text('· $untracked بلا موقع', style: MapStyle.pillLabel(context)),
          ],
        ),
      ),
    );
  }
}

class _LegendEntry extends StatelessWidget {
  const _LegendEntry({required this.health});

  final TrackingHealth health;

  @override
  Widget build(BuildContext context) {
    final colors = context.status(trackingHealthTone(health));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: colors.tint,
            shape: BoxShape.circle,
            border: Border.all(color: colors.ink, width: 1.5),
          ),
        ),
        const SizedBox(width: 4),
        Text(health.label, style: MapStyle.pillLabel(context)),
      ],
    );
  }
}

class _NoPositionsOverlay extends StatelessWidget {
  const _NoPositionsOverlay();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return IgnorePointer(
      child: ColoredBox(
        color: scheme.surface.withAlpha(210),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_off_rounded,
                  size: 34,
                  color: scheme.onSurfaceVariant.withAlpha(150),
                ),
                const SizedBox(height: AppSpacing.small),
                Text(
                  'لا توجد مواقع مباشرة الآن',
                  textAlign: TextAlign.center,
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'تظهر المركبات على الخريطة فور أن يبدأ الكابتن مشاركة موقعه من تطبيق الكابتن.',
                  textAlign: TextAlign.center,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
