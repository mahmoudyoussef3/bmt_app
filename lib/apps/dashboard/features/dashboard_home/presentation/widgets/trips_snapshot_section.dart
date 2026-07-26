import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/routes/dashboard_routes.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/operation_trip.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/empty_state.dart';
import 'package:bmt_app/core/widgets/progress_bar.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../domain/entities/dashboard_home_summary.dart';

/// Merges the spec's "today's trips" and "upcoming trips" into one ranked
/// list (soonest departure, then highest occupancy): once both are backed by
/// real data they show almost the same rows, so a second, near-duplicate
/// section would just repeat them.
class TripsSnapshotSection extends StatelessWidget {
  const TripsSnapshotSection({
    super.key,
    required this.summary,
    required this.onOpenModule,
  });

  final DashboardHomeSummary summary;
  final ValueChanged<String> onOpenModule;

  @override
  Widget build(BuildContext context) {
    final trips = summary.upcomingTrips();
    return DashboardPanel(
      icon: Icons.directions_bus_rounded,
      title: 'الرحلات',
      subtitle: 'الرحلات القادمة، الأقرب موعدًا فالأعلى إشغالًا',
      trailing: TextButton(
        onPressed: () => onOpenModule(DashboardRoutes.trips),
        child: const Text('عرض كل الرحلات'),
      ),
      child: trips.isEmpty
          ? const EmptyState(
              emoji: '🗓️',
              title: 'لا رحلات قادمة',
              subtitle: 'لم يتم جدولة أي رحلة قادمة بعد.',
            )
          : Column(
              children: [
                for (final trip in trips) ...[
                  _TripRow(trip: trip),
                  if (trip != trips.last) const Divider(height: AppSpacing.large),
                ],
              ],
            ),
    );
  }
}

class _TripRow extends StatelessWidget {
  const _TripRow({required this.trip});

  final OperationTrip trip;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final occupancy = trip.capacity == 0
        ? 0.0
        : trip.bookedSeats / trip.capacity;
    final (statusColor, statusBg) = _statusColors(trip.status, scheme);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  trip.route.isEmpty ? 'رحلة بدون مسار' : trip.route,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              StatusChip(label: trip.status.label, color: statusBg, textColor: statusColor),
            ],
          ),
          const SizedBox(height: AppTokens.radiusSmall / 2),
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: 4,
            children: [
              _MetaChip(icon: Icons.access_time_rounded, label: trip.departure),
              _MetaChip(icon: Icons.person_rounded, label: trip.driver.isEmpty ? 'بدون سائق' : trip.driver),
              _MetaChip(icon: Icons.local_shipping_outlined, label: trip.vehicle.isEmpty ? 'بدون مركبة' : trip.vehicle),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Row(
            children: [
              Expanded(child: AppProgressBar(progress: occupancy)),
              const SizedBox(width: AppSpacing.small),
              Text(
                '${trip.bookedSeats}/${trip.capacity}',
                style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }

  (Color, Color) _statusColors(OperationTripStatus status, ColorScheme scheme) {
    return switch (status) {
      OperationTripStatus.inProgress ||
      OperationTripStatus.boarding => (const Color(0xFF22A06B), const Color(0x1A22A06B)),
      OperationTripStatus.completed => (scheme.onSurfaceVariant, scheme.surfaceContainerHighest),
      OperationTripStatus.cancelled => (const Color(0xFFD64545), const Color(0x1AD64545)),
      OperationTripStatus.scheduled ||
      OperationTripStatus.openForBooking => (const Color(0xFF2F80ED), const Color(0x1A2F80ED)),
    };
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: scheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
