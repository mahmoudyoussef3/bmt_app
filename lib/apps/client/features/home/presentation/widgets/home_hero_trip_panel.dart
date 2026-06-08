import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/core/theme/app_typography.dart';
import 'package:bmt_app/core/widgets/app_button.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

/// Home hero card.
///
/// Shows:
/// - No trip state: simple booking search CTA.
/// - Active trip state: current trip summary + full route points timeline.
///
/// Notes:
/// - This widget reads optional trip route points dynamically, so it will still
///   compile even if `HomeCurrentTripData` does not yet have `points`.
/// - Recommended entity fields:
///   final List<HomeTripPointData> points;
///   final int? currentPointIndex;
/// - Latitude/longitude should be stored in data, but not shown to the user.
class HomeHeroTripPanel extends StatelessWidget {
  const HomeHeroTripPanel({
    super.key,
    required this.scheme,
    required this.trip,
    required this.onBookTrip,
    required this.onViewTrip,
    this.onTrackTrip,
  });

  final ColorScheme scheme;
  final HomeCurrentTripData? trip;
  final VoidCallback onBookTrip;
  final VoidCallback onViewTrip;
  final VoidCallback? onTrackTrip;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: trip == null
          ? _NoTripPanel(scheme: scheme, onBookTrip: onBookTrip)
          : _ActiveTripPanel(
              scheme: scheme,
              trip: trip!,
              onViewTrip: onViewTrip,
              onTrackTrip: onTrackTrip,
            ),
    );
  }
}

class _ActiveTripPanel extends StatelessWidget {
  const _ActiveTripPanel({
    required this.scheme,
    required this.trip,
    required this.onViewTrip,
    this.onTrackTrip,
  });

  final ColorScheme scheme;
  final HomeCurrentTripData trip;
  final VoidCallback onViewTrip;
  final VoidCallback? onTrackTrip;

  @override
  Widget build(BuildContext context) {
    final routePoints = _TripRouteReader.pointsFromTrip(trip);
    final currentPointIndex = _TripRouteReader.currentPointIndexFromTrip(trip);
    final isTrackingAvailable = onTrackTrip != null;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outline.withAlpha(55)),
        boxShadow: [
          BoxShadow(
            color: scheme.onSurface.withAlpha(12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onViewTrip,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TripHeader(
                  scheme: scheme,
                  statusLabel: trip.statusLabel,
                  isTrackingAvailable: isTrackingAvailable,
                ),
                const SizedBox(height: 16),
                _TripRouteTimeline(
                  scheme: scheme,
                  points: routePoints,
                  currentPointIndex: currentPointIndex,
                ),
                if (trip.driverLine != null) ...[
                  const SizedBox(height: 16),
                  Divider(height: 1, color: scheme.outline.withAlpha(55)),
                  const SizedBox(height: 14),
                  _DriverSummary(
                    scheme: scheme,
                    driverLine: trip.driverLine!,
                  ),
                ],
                const SizedBox(height: 18),
                _ActionButtons(
                  onTrackTrip: onTrackTrip,
                  onViewTrip: onViewTrip,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TripHeader extends StatelessWidget {
  const _TripHeader({
    required this.scheme,
    required this.statusLabel,
    required this.isTrackingAvailable,
  });

  final ColorScheme scheme;
  final String statusLabel;
  final bool isTrackingAvailable;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: scheme.primary.withAlpha(22),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            isTrackingAvailable
                ? Icons.directions_bus_filled_rounded
                : Icons.event_available_rounded,
            color: scheme.primary,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isTrackingAvailable ? 'رحلتك بدأت' : 'رحلتك القادمة',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                isTrackingAvailable
                    ? 'تابع مسار العربية والمحطة الحالية'
                    : 'راجع تفاصيل الرحلة قبل موعد التحرك',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withAlpha(145),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        StatusChip(label: statusLabel),
      ],
    );
  }
}

class _TripRouteTimeline extends StatelessWidget {
  const _TripRouteTimeline({
    required this.scheme,
    required this.points,
    required this.currentPointIndex,
  });

  final ColorScheme scheme;
  final List<_TripPointUiData> points;
  final int? currentPointIndex;

  @override
  Widget build(BuildContext context) {
    final visiblePoints = _visiblePoints(points);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline.withAlpha(45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RouteTitle(
            scheme: scheme,
            pointsCount: points.length,
            hasCurrentPoint: currentPointIndex != null,
          ),
          const SizedBox(height: 14),
          ...List.generate(visiblePoints.length, (index) {
            final point = visiblePoints[index].point;
            final realIndex = visiblePoints[index].realIndex;

            return _TripPointTile(
              scheme: scheme,
              point: point,
              isFirst: realIndex == 0,
              isLast: realIndex == points.length - 1,
              isPassed: _isPassed(realIndex),
              isCurrent: _isCurrent(realIndex),
              showConnector: index != visiblePoints.length - 1,
            );
          }),
          if (points.length > visiblePoints.length) ...[
            const SizedBox(height: 8),
            Text(
              'يوجد ${points.length - visiblePoints.length} محطات أخرى في تفاصيل الرحلة',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withAlpha(130),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  bool _isCurrent(int index) {
    return currentPointIndex != null && index == currentPointIndex;
  }

  bool _isPassed(int index) {
    return currentPointIndex != null && index < currentPointIndex!;
  }

  List<_VisiblePoint> _visiblePoints(List<_TripPointUiData> allPoints) {
    if (allPoints.length <= 5) {
      return List.generate(
        allPoints.length,
        (index) => _VisiblePoint(point: allPoints[index], realIndex: index),
      );
    }

    final current = currentPointIndex;

    if (current == null) {
      return [
        _VisiblePoint(point: allPoints.first, realIndex: 0),
        _VisiblePoint(point: allPoints[1], realIndex: 1),
        _VisiblePoint(point: allPoints[2], realIndex: 2),
        _VisiblePoint(
          point: allPoints[allPoints.length - 2],
          realIndex: allPoints.length - 2,
        ),
        _VisiblePoint(point: allPoints.last, realIndex: allPoints.length - 1),
      ];
    }

    final start = (current - 1).clamp(0, allPoints.length - 1);
    final end = (current + 1).clamp(0, allPoints.length - 1);

    final indexes = <int>{0, start, current, end, allPoints.length - 1}.toList()
      ..sort();

    return indexes
        .map((index) => _VisiblePoint(point: allPoints[index], realIndex: index))
        .toList();
  }
}

class _RouteTitle extends StatelessWidget {
  const _RouteTitle({
    required this.scheme,
    required this.pointsCount,
    required this.hasCurrentPoint,
  });

  final ColorScheme scheme;
  final int pointsCount;
  final bool hasCurrentPoint;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'مسار الرحلة',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            hasCurrentPoint ? 'تتبع مباشر' : '$pointsCount محطات',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ],
    );
  }
}

class _TripPointTile extends StatelessWidget {
  const _TripPointTile({
    required this.scheme,
    required this.point,
    required this.isFirst,
    required this.isLast,
    required this.isPassed,
    required this.isCurrent,
    required this.showConnector,
  });

  final ColorScheme scheme;
  final _TripPointUiData point;
  final bool isFirst;
  final bool isLast;
  final bool isPassed;
  final bool isCurrent;
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    final color = isPassed
        ? scheme.secondary
        : isCurrent
            ? scheme.primary
            : isLast
                ? scheme.tertiary
                : scheme.outline;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: isCurrent ? 30 : 26,
              height: isCurrent ? 30 : 26,
              decoration: BoxDecoration(
                color: color.withAlpha(isCurrent ? 42 : 26),
                shape: BoxShape.circle,
                border: Border.all(color: color.withAlpha(130), width: 1.4),
              ),
              child: Icon(_icon, size: isCurrent ? 16 : 13, color: color),
            ),
            if (showConnector)
              Container(
                width: 2,
                height: 26,
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: scheme.outline.withAlpha(80),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isCurrent
                            ? scheme.primary
                            : scheme.onSurface.withAlpha(135),
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  point.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight:
                            isCurrent ? FontWeight.w900 : FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData get _icon {
    if (isPassed) return Icons.check_rounded;
    if (isCurrent) return Icons.directions_bus_rounded;
    if (isFirst) return Icons.trip_origin_rounded;
    if (isLast) return Icons.location_on_rounded;
    return Icons.circle_rounded;
  }

  String get _label {
    if (isPassed) return 'تم المرور';
    if (isCurrent) return 'العربية هنا الآن';
    if (isFirst) return 'نقطة البداية';
    if (isLast) return 'نقطة الوصول';
    return 'محطة مرور';
  }
}

class _DriverSummary extends StatelessWidget {
  const _DriverSummary({
    required this.scheme,
    required this.driverLine,
  });

  final ColorScheme scheme;
  final String driverLine;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: scheme.primary.withAlpha(20),
          child: Icon(Icons.person_rounded, color: scheme.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            driverLine,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withAlpha(165),
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
          ),
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.onViewTrip,
    this.onTrackTrip,
  });

  final VoidCallback onViewTrip;
  final VoidCallback? onTrackTrip;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onTrackTrip != null) ...[
          Expanded(
            child: AppButton(
              label: 'تتبع الرحلة',
              onPressed: onTrackTrip!,
              height: 46,
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: AppButton(
            label: 'التفاصيل',
            onPressed: onViewTrip,
            outline: true,
            height: 46,
          ),
        ),
      ],
    );
  }
}

class _NoTripPanel extends StatelessWidget {
  const _NoTripPanel({required this.scheme, required this.onBookTrip});

  final ColorScheme scheme;
  final VoidCallback onBookTrip;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outline.withAlpha(55)),
        boxShadow: [
          BoxShadow(
            color: scheme.onSurface.withAlpha(12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إلى أين تريد الذهاب؟',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 16.5,
                  ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: onBookTrip,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withAlpha(130),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: scheme.outline.withAlpha(45)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: scheme.primary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'ابحث عن وجهتك...',
                        style: TextStyle(
                          color: scheme.onSurface.withAlpha(120),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.my_location_rounded,
                      color: scheme.onSurface.withAlpha(130),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 15,
                  color: scheme.onSurface.withAlpha(110),
                ),
                const SizedBox(width: 6),
                Text(
                  'وجهات سريعة',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withAlpha(120),
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ShortcutChip(
                  scheme: scheme,
                  icon: Icons.work_outline_rounded,
                  label: 'Smart Village',
                  onTap: onBookTrip,
                ),
                _ShortcutChip(
                  scheme: scheme,
                  icon: Icons.train_outlined,
                  label: 'Banha Station',
                  onTap: onBookTrip,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutChip extends StatelessWidget {
  const _ShortcutChip({
    required this.scheme,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final ColorScheme scheme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: scheme.primary.withAlpha(12),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: scheme.primary.withAlpha(30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: scheme.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripRouteReader {
  static List<_TripPointUiData> pointsFromTrip(HomeCurrentTripData trip) {
    try {
      final dynamic dynamicTrip = trip;
      final dynamic rawPoints =
          dynamicTrip.points ?? dynamicTrip.routePoints ?? dynamicTrip.stops;

      if (rawPoints is List && rawPoints.isNotEmpty) {
        return rawPoints.map((point) {
          final dynamic p = point;
          return _TripPointUiData(name: p.name?.toString() ?? p.toString());
        }).toList();
      }
    } catch (_) {}

    return [
      _TripPointUiData(name: trip.pickup),
      _TripPointUiData(name: trip.destination),
    ];
  }

  static int? currentPointIndexFromTrip(HomeCurrentTripData trip) {
    try {
      final dynamic dynamicTrip = trip;
      final dynamic value =
          dynamicTrip.currentPointIndex ?? dynamicTrip.currentStopIndex;

      if (value is int) return value;
      return int.tryParse(value.toString());
    } catch (_) {
      return null;
    }
  }
}

class _TripPointUiData {
  const _TripPointUiData({required this.name});

  final String name;
}

class _VisiblePoint {
  const _VisiblePoint({
    required this.point,
    required this.realIndex,
  });

  final _TripPointUiData point;
  final int realIndex;
}
