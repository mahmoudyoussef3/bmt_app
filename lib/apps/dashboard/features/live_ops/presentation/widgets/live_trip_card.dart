import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/live_ops_snapshot.dart';
import 'departure_status_badge.dart';
import 'live_ops_format.dart';
import 'tracking_health_badge.dart';

/// One trip on the road: route, crew, occupancy and — the reason this screen
/// exists — an honest read of whether its position feed is live, when it last
/// reported, and whether it is running late against its schedule.
///
/// The whole card is tappable: it selects the trip, which focuses the map on it.
/// Selection is drawn as a border plus a raised surface rather than colour
/// alone, so it survives greyscale and high-contrast modes.
class LiveTripCard extends StatelessWidget {
  final LiveTrip trip;
  final DateTime now;
  final bool selected;
  final VoidCallback? onTap;

  const LiveTripCard({
    super.key,
    required this.trip,
    required this.now,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final health = trip.trackingHealthAt(now);
    final age = trip.fixAgeAt(now);

    final card = AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.routeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      trip.statusLabel,
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              TrackingHealthBadge(health: health),
            ],
          ),
          
          Builder(
            builder: (context) {
              final badge = DepartureStatusBadge(trip: trip, now: now);
              if (trip.departureStatusAt(now) == DepartureStatus.pending ||
                  trip.departureStatusAt(now) == DepartureStatus.unknown) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: AppSpacing.small),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: badge,
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.medium),
          _MetaRow(
            icon: Icons.person_rounded,
            label: trip.driverName,
            secondary: trip.driverPhone.isEmpty ? null : trip.driverPhone,
          ),
          const SizedBox(height: AppSpacing.xSmall),
          _MetaRow(
            icon: Icons.directions_bus_rounded,
            label: trip.vehicleLabel,
            secondary: trip.departureTime.isEmpty
                ? null
                : 'الانطلاق ${trip.departureTime}',
          ),
          const SizedBox(height: AppSpacing.medium),
          _OccupancyBar(
            booked: trip.bookedSeats,
            capacity: trip.capacity,
            ratio: trip.occupancyRatio,
          ),
          const SizedBox(height: AppSpacing.small),
          _TrackingLine(health: health, age: age, fix: trip.lastFix),
        ],
      ),
    );

    if (onTap == null) return card;

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.radius),
            border: Border.all(
              color: selected ? scheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: card,
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? secondary;

  const _MetaRow({required this.icon, required this.label, this.secondary});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: scheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.bodyMedium,
          ),
        ),
        if (secondary != null) ...[
          const SizedBox(width: AppSpacing.small),
          
          Flexible(
            child: Text(
              secondary!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ],
    );
  }
}

class _OccupancyBar extends StatelessWidget {
  final int booked;
  final int capacity;
  final double ratio;

  const _OccupancyBar({
    required this.booked,
    required this.capacity,
    required this.ratio,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'الإشغال',
              style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const Spacer(),
            Text(
              '$booked / $capacity',
              style: text.labelMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: ratio.clamp(0, 1),
            minHeight: 6,
            backgroundColor: scheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(scheme.primary),
          ),
        ),
      ],
    );
  }
}

class _TrackingLine extends StatelessWidget {
  final TrackingHealth health;
  final Duration? age;
  final LiveFix? fix;

  const _TrackingLine({required this.health, required this.age, this.fix});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final String message;
    if (health == TrackingHealth.unknown || age == null) {
      message = 'لم يُشارك الموقع بعد';
    } else {
      final speed = fix?.speedKph;
      final speedText = (speed != null && speed >= 1)
          ? ' · ${speed.round()} كم/س'
          : '';
      message = 'آخر تحديث ${liveOpsAgo(age!)}$speedText';
    }

    return Row(
      children: [
        Icon(
          Icons.my_location_rounded,
          size: 14,
          color: scheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            message,
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
