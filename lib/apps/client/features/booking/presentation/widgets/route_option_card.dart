import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';

class RouteOptionCard extends StatelessWidget {
  const RouteOptionCard({
    super.key,
    required this.route,
    required this.onTap,
    this.selected = false,
  });

  final RouteOptionData route;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final points = _extractRoutePoints(route);
    final hasSavedStations = route.points.isNotEmpty;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: selected
            ? ClientColors.primaryLight
            : ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? ClientColors.primary
                    : ClientColors.borderFor(context),
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(route: route, selected: selected),
                const SizedBox(height: 14),
                _MainRouteLine(points: points),
                const SizedBox(height: 14),
                _CompactPointsPreview(
                  points: points,
                  hasSavedStations: hasSavedStations,
                ),
                if (points.where((p) => p.hasCoordinates).length >= 2) ...[
                  const SizedBox(height: 12),
                  _StationsMiniMap(points: points),
                ],
                const SizedBox(height: 14),
                Divider(color: ClientColors.borderFor(context)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _MetaItem(
                      icon: Icons.schedule_rounded,
                      label: route.duration,
                    ),
                    const SizedBox(width: 14),
                    _MetaItem(
                      icon: Icons.event_seat_rounded,
                      label: '${route.availableSeats} seats',
                    ),
                    const Spacer(),
                    Text(
                      route.startingPrice,
                      style: ClientTypography.priceMedium(
                        context,
                      ).copyWith(color: ClientColors.primary, fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<RoutePointUiData> _extractRoutePoints(RouteOptionData route) {
    if (route.points.isNotEmpty) {
      return route.points
          .map(
            (point) => RoutePointUiData(
              name: point.name,
              latitude: point.latitude,
              longitude: point.longitude,
            ),
          )
          .toList();
    }

    return [
      RoutePointUiData(name: route.pickup),
      RoutePointUiData(name: route.destination),
    ];
  }
}

class RoutePointUiData {
  const RoutePointUiData({required this.name, this.latitude, this.longitude});

  final String name;
  final double? latitude;
  final double? longitude;

  bool get hasCoordinates => latitude != null && longitude != null;

  LatLng get latLng => LatLng(latitude!, longitude!);
}

class _StationsMiniMap extends StatelessWidget {
  const _StationsMiniMap({required this.points});

  final List<RoutePointUiData> points;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final geoPoints = points.where((point) => point.hasCoordinates).toList();
    final center = _center(geoPoints);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 156,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 11,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.bmt.app',
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: geoPoints.map((point) => point.latLng).toList(),
                  color: scheme.primary,
                  strokeWidth: 4,
                  borderColor: Colors.white,
                  borderStrokeWidth: 2,
                ),
              ],
            ),
            MarkerLayer(
              markers: geoPoints.indexed.map((entry) {
                final index = entry.$1;
                final point = entry.$2;
                final isEdge = index == 0 || index == geoPoints.length - 1;
                return Marker(
                  point: point.latLng,
                  width: isEdge ? 34 : 24,
                  height: isEdge ? 34 : 24,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isEdge
                          ? scheme.primary
                          : ClientColors.surfaceFor(context),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isEdge ? Colors.white : scheme.primary,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(45),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isEdge ? Colors.white : scheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  LatLng _center(List<RoutePointUiData> points) {
    final lat =
        points
            .map((point) => point.latitude!)
            .reduce((value, element) => value + element) /
        points.length;
    final lng =
        points
            .map((point) => point.longitude!)
            .reduce((value, element) => value + element) /
        points.length;
    return LatLng(lat, lng);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.route, required this.selected});

  final RouteOptionData route;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (route.isFastest) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: ClientColors.primaryLight,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Fastest',
              style: ClientTypography.labelSmall(context).copyWith(
                color: ClientColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        if (selected)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: ClientColors.primaryLight,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Selected',
              style: ClientTypography.labelSmall(context).copyWith(
                color: ClientColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        const Spacer(),
        Icon(
          selected ? Icons.check_circle_rounded : Icons.circle_outlined,
          color: selected
              ? ClientColors.primary
              : ClientColors.borderFor(context),
        ),
      ],
    );
  }
}

class _MainRouteLine extends StatelessWidget {
  const _MainRouteLine({required this.points});

  final List<RoutePointUiData> points;

  @override
  Widget build(BuildContext context) {
    final start = points.first.name;
    final end = points.last.name;

    return Row(
      children: [
        Expanded(
          child: _PointBlock(label: 'From', value: start),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Icon(Icons.arrow_back_rounded),
        ),
        Expanded(
          child: _PointBlock(label: 'To', value: end),
        ),
      ],
    );
  }
}

class _PointBlock extends StatelessWidget {
  const _PointBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: ClientTypography.bodySmall(
            context,
          ).copyWith(color: ClientColors.textSecondaryFor(context)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: ClientTypography.bodyMedium(
            context,
          ).copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _CompactPointsPreview extends StatelessWidget {
  const _CompactPointsPreview({
    required this.points,
    required this.hasSavedStations,
  });

  final List<RoutePointUiData> points;
  final bool hasSavedStations;

  @override
  Widget build(BuildContext context) {
    final previewPoints = hasSavedStations
        ? points
        : points.length > 2
        ? points.sublist(1, points.length - 1)
        : <RoutePointUiData>[];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ClientColors.surfaceMutedFor(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasSavedStations
                ? '${points.length} route stops'
                : previewPoints.isEmpty
                ? 'Direct trip with no intermediate stops'
                : '${previewPoints.length} intermediate stops',
            style: ClientTypography.bodySmall(
              context,
            ).copyWith(fontWeight: FontWeight.w800),
          ),
          if (previewPoints.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: previewPoints.take(4).map((point) {
                return _StopChip(label: point.name);
              }).toList(),
            ),
            if (previewPoints.length > 4) ...[
              const SizedBox(height: 8),
              Text(
                '+ ${previewPoints.length - 4} more stops',
                style: ClientTypography.bodySmall(
                  context,
                ).copyWith(color: ClientColors.textSecondaryFor(context)),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _StopChip extends StatelessWidget {
  const _StopChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: ClientColors.primaryLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: ClientTypography.bodySmall(
          context,
        ).copyWith(color: ClientColors.primary, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: ClientColors.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: ClientTypography.bodySmall(
            context,
          ).copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
