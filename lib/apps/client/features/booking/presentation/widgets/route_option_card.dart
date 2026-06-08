import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/core/theme/text_themes.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

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
    final scheme = Theme.of(context).colorScheme;
    final points = _extractRoutePoints(route);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(route: route, selected: selected),
            const SizedBox(height: 14),
            _MainRouteLine(points: points),
            const SizedBox(height: 14),
            _CompactPointsPreview(points: points),
            const SizedBox(height: 14),
            const AppSeparator(),
            const SizedBox(height: 12),
            Row(
              children: [
                _MetaItem(icon: Icons.schedule_rounded, label: route.duration),
                const SizedBox(width: 14),
                _MetaItem(
                  icon: Icons.event_seat_rounded,
                  label: '${route.availableSeats} مقاعد',
                ),
                const Spacer(),
                Text(
                  route.startingPrice,
                  style: AppTextThemes.priceEmphasis(scheme).copyWith(fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<RoutePointUiData> _extractRoutePoints(RouteOptionData route) {
    try {
      final dynamic dynamicRoute = route;
      final dynamic points = dynamicRoute.points ?? dynamicRoute.stops;

      if (points is List && points.isNotEmpty) {
        return points.map((point) {
          final dynamic p = point;
          return RoutePointUiData(
            name: p.name?.toString() ?? p.toString(),
            latitude: _toDouble(p.latitude),
            longitude: _toDouble(p.longitude),
          );
        }).toList();
      }
    } catch (_) {}

    return [
      RoutePointUiData(name: route.pickup),
      RoutePointUiData(name: route.destination),
    ];
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

class RoutePointUiData {
  const RoutePointUiData({
    required this.name,
    this.latitude,
    this.longitude,
  });

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
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        if (route.isFastest) ...[
          const AppBadge(text: 'الأسرع'),
          const SizedBox(width: 8),
        ],
        if (selected) const AppBadge(text: 'مختار'),
        const Spacer(),
        Icon(
          selected ? Icons.check_circle_rounded : Icons.circle_outlined,
          color: selected ? scheme.primary : scheme.outline,
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
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: scheme.onSurface,
              ),
        ),
      ],
    );
  }
}

class _CompactPointsPreview extends StatelessWidget {
  const _CompactPointsPreview({required this.points});

  final List<RoutePointUiData> points;

  @override
  Widget build(BuildContext context) {
    final middlePoints = points.length > 2
        ? points.sublist(1, points.length - 1)
        : <RoutePointUiData>[];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(80),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            middlePoints.isEmpty
                ? 'رحلة مباشرة بدون محطات مرور'
                : '${middlePoints.length} محطات مرور',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          if (middlePoints.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: middlePoints.take(4).map((point) {
                return _StopChip(label: point.name);
              }).toList(),
            ),
            if (middlePoints.length > 4) ...[
              const SizedBox(height: 8),
              Text(
                '+ ${middlePoints.length - 4} محطات أخرى',
                style: Theme.of(context).textTheme.bodySmall,
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
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: scheme.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.primary,
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
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: scheme.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}