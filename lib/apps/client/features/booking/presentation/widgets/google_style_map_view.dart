import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';

enum MapSelectionMode { pickup, destination }

/// Production map view backed by OpenStreetMap tiles.
class GoogleStyleMapView extends StatelessWidget {
  const GoogleStyleMapView({
    super.key,
    required this.pickup,
    required this.destination,
    required this.selectionMode,
    required this.onMapTap,
    this.pickupOffset,
    this.destinationOffset,
  });

  final MapPinOption? pickup;
  final MapPinOption? destination;
  final MapSelectionMode selectionMode;
  final VoidCallback onMapTap;
  final Offset? pickupOffset;
  final Offset? destinationOffset;

  static const _fallbackCenter = LatLng(30.0444, 31.2357);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pickupPoint = _latLngFor(pickup);
    final destinationPoint = _latLngFor(destination);
    final routePoints = [?pickupPoint, ?destinationPoint];
    final center = _centerFor(routePoints);

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: routePoints.length > 1 ? 11 : 12,
            minZoom: 6,
            maxZoom: 18,
            onTap: (_, point) => onMapTap(),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.bmt.app',
            ),
            if (routePoints.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routePoints,
                    color: scheme.primary,
                    strokeWidth: 5,
                    borderColor: Colors.white,
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                if (pickupPoint != null)
                  _marker(
                    context,
                    point: pickupPoint,
                    label: 'A',
                    color: scheme.secondary,
                    active: selectionMode == MapSelectionMode.pickup,
                  ),
                if (destinationPoint != null)
                  _marker(
                    context,
                    point: destinationPoint,
                    label: 'B',
                    color: scheme.error,
                    active: selectionMode == MapSelectionMode.destination,
                  ),
              ],
            ),
          ],
        ),
        Positioned(
          top: 12,
          left: 12,
          child: _MapChip(
            icon: Icons.layers_rounded,
            label: routePoints.length > 1 ? 'Live route map' : 'Stations map',
          ),
        ),
      ],
    );
  }

  Marker _marker(
    BuildContext context, {
    required LatLng point,
    required String label,
    required Color color,
    required bool active,
  }) {
    return Marker(
      point: point,
      width: 54,
      height: 64,
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: active ? 42 : 36,
            height: active ? 42 : 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: active ? 4 : 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(80),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Icon(Icons.arrow_drop_down_rounded, color: color, size: 28),
        ],
      ),
    );
  }

  LatLng? _latLngFor(MapPinOption? pin) {
    if (pin == null) return null;
    final lat = pin.x;
    final lng = pin.y;
    if (lat.abs() > 90 || lng.abs() > 180) return null;
    return LatLng(lat, lng);
  }

  LatLng _centerFor(List<LatLng> points) {
    if (points.isEmpty) return _fallbackCenter;
    final lat = points.map((point) => point.latitude).reduce((a, b) => a + b);
    final lng = points.map((point) => point.longitude).reduce((a, b) => a + b);
    return LatLng(lat / points.length, lng / points.length);
  }
}

class _MapChip extends StatelessWidget {
  const _MapChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(150),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
