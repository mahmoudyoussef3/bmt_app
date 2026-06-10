import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/progress_bar.dart';
import '../../domain/entities/live_trip.dart';

class LiveTripCard extends StatelessWidget {
  const LiveTripCard({
    super.key,
    required this.trip,
    required this.selected,
    required this.onTap,
  });

  final LiveTrip trip;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final scheduledStartStr = '${trip.scheduledStartTime.hour.toString().padLeft(2, '0')}:${trip.scheduledStartTime.minute.toString().padLeft(2, '0')}';
    final actualStartStr = trip.actualStartTime != null
        ? '${trip.actualStartTime!.hour.toString().padLeft(2, '0')}:${trip.actualStartTime!.minute.toString().padLeft(2, '0')}'
        : '-';
    final expectedArrivalStr = trip.expectedArrivalTime != null
        ? '${trip.expectedArrivalTime!.hour.toString().padLeft(2, '0')}:${trip.expectedArrivalTime!.minute.toString().padLeft(2, '0')}'
        : '-';

    return AppCard(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(AppSpacing.small),
        decoration: BoxDecoration(
          color: selected ? scheme.primary.withAlpha(12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outline.withAlpha(45),
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    trip.routeName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                _HealthChip(health: trip.health),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${trip.tripCode} · ${trip.status.label}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.medium),
            _Fact(icon: Icons.person_outline, label: trip.driverName),
            _Fact(icon: Icons.directions_bus_outlined, label: '${trip.vehicleType} · ${trip.vehiclePlate}'),
            _Fact(
              icon: Icons.place_outlined,
              label: '${trip.currentPoint?.name ?? '-'} → ${trip.nextPoint?.name ?? 'نهاية الرحلة'}',
            ),
            const SizedBox(height: AppSpacing.small),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _TimeFact(label: 'البداية المخططة', value: scheduledStartStr),
                _TimeFact(label: 'البداية الفعلية', value: actualStartStr),
                _TimeFact(label: 'الوصول المتوقع', value: expectedArrivalStr),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            AppProgressBar(progress: trip.progressPercent / 100),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'الركاب ${trip.checkedInPassengersCount}/${trip.passengersCount}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (trip.unresolvedAlertsCount > 0)
                  Text(
                    '${trip.unresolvedAlertsCount} تنبيهات',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.error,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(icon, size: 17, color: scheme.onSurfaceVariant),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthChip extends StatelessWidget {
  const _HealthChip({required this.health});

  final LiveTripHealth health;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (health) {
      LiveTripHealth.normal => scheme.primary,
      LiveTripHealth.delayed => scheme.tertiary,
      LiveTripHealth.warning => scheme.tertiary,
      LiveTripHealth.critical => scheme.error,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        health.label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _TimeFact extends StatelessWidget {
  const _TimeFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: scheme.onSurfaceVariant,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
        ),
      ],
    );
  }
}
