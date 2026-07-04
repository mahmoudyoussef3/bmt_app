import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';

/// A route map backed by OpenStreetMap.
///
/// The camera always fits the supplied route instead of relying on a fixed
/// city-level zoom. Invalid coordinates are ignored so the UI never renders a
/// plausible-looking marker for data that does not exist.
class GoogleStyleMapView extends StatelessWidget {
  const GoogleStyleMapView({
    super.key,
    this.pickup,
    this.destination,
    this.waypoints = const [],
    this.cameraPadding = const EdgeInsets.all(48),
    this.interactive = true,
  });

  final MapPinOption? pickup;
  final MapPinOption? destination;
  final List<MapPinOption> waypoints;
  final EdgeInsets cameraPadding;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    final mapPoints = _mapPoints();
    if (mapPoints.isEmpty) return const _NoCoordinatesPanel();

    final coordinates = mapPoints.map((item) => item.coordinate).toList();
    final center = _centerFor(coordinates);
    final cameraFit = coordinates.length > 1
        ? CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(coordinates),
            padding: cameraPadding,
            maxZoom: 15,
          )
        : null;
    final mapKey = ValueKey(
      coordinates
          .map(
            (point) =>
                '${point.latitude.toStringAsFixed(5)},'
                '${point.longitude.toStringAsFixed(5)}',
          )
          .join('|'),
    );

    return Stack(
      children: [
        FlutterMap(
          key: mapKey,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 14,
            initialCameraFit: cameraFit,
            minZoom: 5,
            maxZoom: 18,
            interactionOptions: InteractionOptions(
              flags: interactive
                  ? InteractiveFlag.drag |
                        InteractiveFlag.pinchZoom |
                        InteractiveFlag.doubleTapZoom
                  : InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.bmt.app',
            ),
            if (coordinates.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: coordinates,
                    color: ClientColors.primaryFor(context),
                    strokeWidth: 5,
                    borderColor: Colors.white,
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
            MarkerLayer(
              markers: mapPoints.indexed.map((entry) {
                final index = entry.$1;
                final item = entry.$2;
                return _marker(
                  context,
                  point: item.coordinate,
                  label: _markerLabel(index, mapPoints.length),
                  color: _markerColor(context, index, mapPoints.length),
                  prominent: index == 0 || index == mapPoints.length - 1,
                );
              }).toList(),
            ),
          ],
        ),
        PositionedDirectional(
          top: 12,
          start: 12,
          child: _MapChip(
            icon: Icons.route_rounded,
            label: mapPoints.length == 1
                ? '1 mapped station'
                : '${mapPoints.length} mapped stations',
          ),
        ),
        PositionedDirectional(
          end: 5,
          bottom: 5,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            color: ClientColors.surfaceFor(context).withAlpha(215),
            child: Text(
              '© OpenStreetMap',
              style: ClientTypography.labelSmall(context).copyWith(fontSize: 9),
            ),
          ),
        ),
      ],
    );
  }

  List<_MapPoint> _mapPoints() {
    final pins = waypoints.isNotEmpty
        ? waypoints
        : <MapPinOption>[?pickup, ?destination];
    final points = <_MapPoint>[];
    final seen = <String>{};

    for (final pin in pins) {
      final coordinate = _latLngFor(pin);
      if (coordinate == null) continue;
      final key =
          '${coordinate.latitude.toStringAsFixed(6)}:'
          '${coordinate.longitude.toStringAsFixed(6)}';
      if (!seen.add(key)) continue;
      points.add(_MapPoint(coordinate: coordinate));
    }
    return points;
  }

  Marker _marker(
    BuildContext context, {
    required LatLng point,
    required String label,
    required Color color,
    required bool prominent,
  }) {
    final size = prominent ? 42.0 : 32.0;
    return Marker(
      point: point,
      width: prominent ? 54 : 40,
      height: prominent ? 70 : 54,
      alignment: Alignment.topCenter,
      child: Semantics(
        label: 'Route station $label',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: ClientColors.shadowFor(context).withAlpha(70),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: prominent ? 13 : 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Icon(
              Icons.arrow_drop_down_rounded,
              color: color,
              size: prominent ? 26 : 20,
            ),
          ],
        ),
      ),
    );
  }

  String _markerLabel(int index, int count) {
    if (index == 0) return 'A';
    if (index == count - 1) return 'B';
    return '${index + 1}';
  }

  Color _markerColor(BuildContext context, int index, int count) {
    if (index == 0) return ClientColors.journeyGreen;
    if (index == count - 1) return Theme.of(context).colorScheme.error;
    return ClientColors.primaryFor(context);
  }

  LatLng? _latLngFor(MapPinOption pin) {
    final lat = pin.x;
    final lng = pin.y;
    if (!lat.isFinite ||
        !lng.isFinite ||
        (lat == 0 && lng == 0) ||
        lat < -90 ||
        lat > 90 ||
        lng < -180 ||
        lng > 180) {
      return null;
    }
    return LatLng(lat, lng);
  }

  LatLng _centerFor(List<LatLng> points) {
    final lat = points.map((point) => point.latitude).reduce((a, b) => a + b);
    final lng = points.map((point) => point.longitude).reduce((a, b) => a + b);
    return LatLng(lat / points.length, lng / points.length);
  }
}

class _MapPoint {
  const _MapPoint({required this.coordinate});

  final LatLng coordinate;
}

class _NoCoordinatesPanel extends StatelessWidget {
  const _NoCoordinatesPanel();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ClientColors.surfaceMutedFor(context),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: ClientColors.surfaceFor(context),
                  borderRadius: BorderRadius.circular(ClientRadius.lg),
                ),
                child: Icon(
                  Icons.location_off_outlined,
                  color: ClientColors.textTertiaryFor(context),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Map coordinates unavailable',
                textAlign: TextAlign.center,
                style: ClientTypography.labelLarge(context),
              ),
              const SizedBox(height: 4),
              Text(
                'The route details are still available below.',
                textAlign: TextAlign.center,
                style: ClientTypography.bodySmall(
                  context,
                ).copyWith(color: ClientColors.textSecondaryFor(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapChip extends StatelessWidget {
  const _MapChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context).withAlpha(235),
        borderRadius: BorderRadius.circular(ClientRadius.pill),
        border: Border.all(color: ClientColors.borderFor(context)),
        boxShadow: ClientElevation.sm(context),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: ClientColors.primaryFor(context)),
          const SizedBox(width: 6),
          Text(
            label,
            style: ClientTypography.labelSmall(
              context,
            ).copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
