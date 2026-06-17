import 'package:flutter/material.dart';
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
                      label: '${route.availableSeats} مقاعد',
                    ),
                    const Spacer(),
                    Text(
                      route.startingPrice,
                      style: ClientTypography.priceMedium(context).copyWith(
                        color: ClientColors.primary,
                        fontSize: 16,
                      ),
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
              'الأسرع',
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
              'مختار',
              style: ClientTypography.labelSmall(context).copyWith(
                color: ClientColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        const Spacer(),
        Icon(
          selected ? Icons.check_circle_rounded : Icons.circle_outlined,
          color: selected ? ClientColors.primary : ClientColors.borderFor(context),
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
        Expanded(child: _PointBlock(label: 'من', value: start)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Icon(Icons.arrow_back_rounded),
        ),
        Expanded(child: _PointBlock(label: 'إلى', value: end)),
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
          style: ClientTypography.bodySmall(context).copyWith(
            color: ClientColors.textSecondaryFor(context),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: ClientTypography.bodyMedium(context).copyWith(
            fontWeight: FontWeight.w900,
          ),
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
                ? '${points.length} محطات على المسار'
                : previewPoints.isEmpty
                ? 'رحلة مباشرة بدون محطات مرور'
                : '${previewPoints.length} محطات مرور',
            style: ClientTypography.bodySmall(context).copyWith(
              fontWeight: FontWeight.w800,
            ),
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
                '+ ${previewPoints.length - 4} محطات أخرى',
                style: ClientTypography.bodySmall(context).copyWith(
                  color: ClientColors.textSecondaryFor(context),
                ),
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
        style: ClientTypography.bodySmall(context).copyWith(
          color: ClientColors.primary,
          fontWeight: FontWeight.w700,
        ),
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
          style: ClientTypography.bodySmall(context).copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
