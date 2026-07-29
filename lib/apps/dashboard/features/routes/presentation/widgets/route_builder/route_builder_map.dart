import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:bmt_app/core/geo/geo_models.dart';
import 'package:bmt_app/core/maps/map_route_stop.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/maps/controls/map_control_cluster.dart';
import 'package:bmt_app/core/widgets/maps/easyway_tile_layer.dart';
import 'package:bmt_app/core/widgets/maps/map_camera_animator.dart';
import 'package:bmt_app/core/widgets/maps/markers/station_marker.dart';
import 'package:bmt_app/core/widgets/maps/overlays/glass_info_card.dart';
import 'package:bmt_app/core/widgets/maps/overlays/map_attribution.dart';
import 'package:bmt_app/core/widgets/maps/route_polyline_layers.dart';

import '../../../domain/entities/route_draft.dart';

/// The builder's map: the same EasyWay map surface the client and captain apps
/// use (basemap, route stroke, station pins), turned into an editor.
///
/// It is always on screen beside the stop list — the previous form stacked the
/// map above the list in a page-long scroll, so placing a point meant scrolling
/// up, clicking, and scrolling back down for every stop.
class RouteBuilderMap extends StatefulWidget {
  final List<RouteStopDraft> stops;

  /// Road shape from the directions provider; straight lines are drawn between
  /// stops until it arrives.
  final List<GeoPoint> path;
  final int activeIndex;
  final bool picking;
  final ValueChanged<GeoPoint> onMapTap;
  final ValueChanged<int> onStopTap;
  final VoidCallback onCancelPicking;

  const RouteBuilderMap({
    super.key,
    required this.stops,
    required this.path,
    required this.activeIndex,
    required this.picking,
    required this.onMapTap,
    required this.onStopTap,
    required this.onCancelPicking,
  });

  @override
  State<RouteBuilderMap> createState() => _RouteBuilderMapState();
}

class _RouteBuilderMapState extends State<RouteBuilderMap>
    with SingleTickerProviderStateMixin {
  static const _fallbackCenter = LatLng(30.0444, 31.2357); // Cairo

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
  void didUpdateWidget(RouteBuilderMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_ready) return;

    // Following the operator: focusing a stop centres it, changing the shape of
    // the route re-frames the whole thing.
    if (widget.activeIndex != oldWidget.activeIndex) {
      final point = _pointAt(widget.activeIndex);
      if (point != null) {
        _camera.animateTo(
          center: point,
          zoom: _controller.camera.zoom < 13 ? 14 : _controller.camera.zoom,
        );
        return;
      }
    }
    if (_shapeSignature(widget.stops) != _shapeSignature(oldWidget.stops)) {
      _fitRoute();
    }
  }

  @override
  void dispose() {
    _camera.dispose();
    super.dispose();
  }

  LatLng? _pointAt(int index) {
    if (index < 0 || index >= widget.stops.length) return null;
    final point = widget.stops[index].point;
    return point == null ? null : LatLng(point.lat, point.lng);
  }

  static String _shapeSignature(List<RouteStopDraft> stops) => stops
      .map((stop) => stop.point == null ? '-' : '${stop.point!.lat},${stop.point!.lng}')
      .join('|');

  List<LatLng> get _locatedPoints => widget.stops
      .where((stop) => stop.point != null)
      .map((stop) => LatLng(stop.point!.lat, stop.point!.lng))
      .toList();

  void _fitRoute() {
    final points = _locatedPoints;
    if (points.isEmpty) return;
    if (points.length == 1) {
      _camera.animateTo(center: points.first, zoom: 14);
      return;
    }
    _camera.animateFit(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(72),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final located = _locatedPoints;
    final line = widget.path.length >= 2
        ? widget.path.map((point) => LatLng(point.lat, point.lng)).toList()
        : located;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: located.isEmpty ? _fallbackCenter : located.first,
              initialZoom: located.isEmpty ? 9 : 12,
              minZoom: 4,
              maxZoom: 18,
              onMapReady: () {
                _ready = true;
                if (located.length >= 2) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _fitRoute();
                  });
                }
              },
              onTap: (_, latLng) =>
                  widget.onMapTap(GeoPoint(latLng.latitude, latLng.longitude)),
            ),
            children: [
              const EasyWayTileLayer(),
              if (line.length >= 2)
                PolylineLayer(polylines: buildRoutePolylines(context, line)),
              MarkerLayer(
                markers: [
                  for (final entry in widget.stops.indexed)
                    if (entry.$2.point != null)
                      buildStationMarker(
                        context,
                        stop: MapRouteStop(
                          coordinate: LatLng(
                            entry.$2.point!.lat,
                            entry.$2.point!.lng,
                          ),
                          name: entry.$2.name,
                        ),
                        index: entry.$1,
                        count: widget.stops.length,
                        selected: entry.$1 == widget.activeIndex,
                        onTap: () => widget.onStopTap(entry.$1),
                      ),
                ],
              ),
            ],
          ),
          if (widget.picking) const _PickingFrame(),
          PositionedDirectional(
            top: AppSpacing.medium,
            start: AppSpacing.medium,
            end: AppSpacing.medium,
            child: _MapBanner(
              picking: widget.picking,
              activeLabel: _activeLabel(),
              hasPoints: located.isNotEmpty,
              onCancel: widget.onCancelPicking,
            ),
          ),
          PositionedDirectional(
            bottom: AppSpacing.medium,
            end: AppSpacing.medium,
            child: MapControlCluster(
              onRecenter: _fitRoute,
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
    );
  }

  String _activeLabel() {
    final index = widget.activeIndex;
    if (index < 0 || index >= widget.stops.length) return '';
    final name = widget.stops[index].name.trim();
    if (name.isNotEmpty) return name;
    if (index == 0) return 'نقطة الانطلاق';
    if (index == widget.stops.length - 1) return 'الوجهة النهائية';
    return 'محطة $index';
  }
}

/// Brand-coloured outline drawn only while the map is armed, so it is
/// unmistakable that the next click on the map lands a point.
class _PickingFrame extends StatelessWidget {
  const _PickingFrame();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.primary,
              width: 3,
            ),
            borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
          ),
        ),
      ),
    );
  }
}

class _MapBanner extends StatelessWidget {
  final bool picking;
  final String activeLabel;
  final bool hasPoints;
  final VoidCallback onCancel;

  const _MapBanner({
    required this.picking,
    required this.activeLabel,
    required this.hasPoints,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (!picking && hasPoints) return const SizedBox.shrink();

    final message = picking
        ? 'اضغط على الخريطة لتحديد موقع: $activeLabel'
        : 'ابحث عن نقطة الانطلاق والوجهة، أو حدّدهما على الخريطة';

    return Align(
      alignment: AlignmentDirectional.topCenter,
      child: GlassInfoCard(
        maxWidth: 520,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              picking ? Icons.ads_click_rounded : Icons.travel_explore_rounded,
              size: 18,
              color: scheme.primary,
            ),
            const SizedBox(width: AppSpacing.small),
            Flexible(
              child: Text(
                message,
                style: Theme.of(context).textTheme.labelLarge,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (picking) ...[
              const SizedBox(width: AppSpacing.small),
              TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('إلغاء'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

