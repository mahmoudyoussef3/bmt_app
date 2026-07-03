import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_spacing.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_button.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_card.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_status_chip.dart';

import '../../domain/entities/assigned_trip.dart';

class AssignedTripCard extends StatelessWidget {
  const AssignedTripCard({
    super.key,
    required this.trip,
    required this.onOpen,
    required this.onManifest,
  });

  final AssignedTrip trip;
  final VoidCallback onOpen;
  final VoidCallback onManifest;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = trip.passengerCount == 0
        ? 0.0
        : trip.boardedCount / trip.passengerCount;

    return CaptainCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header section
          Container(
            padding: const EdgeInsets.all(CaptainSpacing.xl),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withAlpha(50),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(CaptainRadius.xl)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        trip.route,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _StatusBadge(status: trip.status),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _IconDetail(
                      icon: Icons.directions_bus_rounded,
                      text: trip.vehicleNumber.isEmpty ? 'مركبة غير محددة' : trip.vehicleNumber,
                    ),
                    const SizedBox(width: 16),
                    _IconDetail(
                      icon: Icons.schedule_rounded,
                      text: _timeRange(trip),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(height: 1, thickness: 1, color: scheme.outline.withAlpha(20)),

          // Body section with progress and actions
          Padding(
            padding: const EdgeInsets.all(CaptainSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Boarding Progress
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'الركاب (${trip.passengerCount})',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: scheme.primary,
                            ),
                        children: [
                          TextSpan(text: '${trip.boardedCount} '),
                          TextSpan(
                            text: 'صعدوا',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: CaptainSpacing.md),
                ClipRRect(
                  borderRadius: CaptainRadius.rSm,
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: scheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress == 1.0 ? Colors.green : scheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: CaptainSpacing.xxl),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: CaptainButton(
                        label: 'بدء / متابعة',
                        icon: Icons.navigation_rounded,
                        onPressed: onOpen,
                        variant: CaptainButtonVariant.primary,
                      ),
                    ),
                    const SizedBox(width: CaptainSpacing.md),
                    Expanded(
                      flex: 1,
                      child: CaptainButton(
                        label: 'القائمة',
                        icon: Icons.group_rounded,
                        onPressed: onManifest,
                        variant: CaptainButtonVariant.outline,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeRange(AssignedTrip trip) {
    return '${_time(trip.departureTime)} - ${_time(trip.expectedArrivalTime)}';
  }

  String _time(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final AssignedTripStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, variant, icon) = switch (status) {
      AssignedTripStatus.scheduled => ('مجدولة', CaptainStatusVariant.info, Icons.event_rounded),
      AssignedTripStatus.boarding => ('صعود', CaptainStatusVariant.warning, Icons.people_rounded),
      AssignedTripStatus.inProgress => ('جارية', CaptainStatusVariant.success, Icons.electric_car_rounded),
      AssignedTripStatus.completed => ('مكتملة', CaptainStatusVariant.neutral, Icons.check_circle_rounded),
    };

    return CaptainStatusChip(
      label: label,
      variant: variant,
      icon: icon,
    );
  }
}

class _IconDetail extends StatelessWidget {
  const _IconDetail({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: scheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
