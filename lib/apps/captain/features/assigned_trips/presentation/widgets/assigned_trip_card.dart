import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_button.dart';
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
    final progress = trip.passengerCount == 0
        ? 0.0
        : trip.boardedCount / trip.passengerCount;

    return Container(
      decoration: BoxDecoration(
        color: CaptainColors.surfaceFor(context),
        borderRadius: CaptainDesignTokens.br24,
        boxShadow: CaptainDesignTokens.floatingShadow(context),
        border: Border.all(color: CaptainColors.primary.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header section
          Container(
            padding: const EdgeInsets.all(CaptainDesignTokens.s24),
            decoration: BoxDecoration(
              color: CaptainColors.primary.withValues(alpha: 0.03),
              borderRadius: const BorderRadius.vertical(
                top: CaptainDesignTokens.r24,
              ),
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
                        style: CaptainTypography.titleLarge(context).copyWith(
                          fontWeight: FontWeight.w800,
                          color: CaptainColors.textPrimaryFor(context),
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: CaptainDesignTokens.s12),
                    _StatusBadge(status: trip.status),
                  ],
                ),
                const SizedBox(height: CaptainDesignTokens.s16),
                Row(
                  children: [
                    _IconDetail(
                      icon: Icons.directions_bus_rounded,
                      text: trip.vehicleNumber.isEmpty
                          ? 'مركبة غير محددة'
                          : trip.vehicleNumber,
                    ),
                    const SizedBox(width: CaptainDesignTokens.s16),
                    _IconDetail(
                      icon: Icons.schedule_rounded,
                      text: _timeRange(trip),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            thickness: 1,
            color: CaptainColors.dividerFor(context),
          ),

          // Body section with progress and actions
          Padding(
            padding: const EdgeInsets.all(CaptainDesignTokens.s24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Boarding Progress
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'الركاب (${trip.passengerCount})',
                      style: CaptainTypography.titleSmall(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: CaptainColors.textSecondaryFor(context),
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        style: CaptainTypography.titleMedium(context).copyWith(
                          fontWeight: FontWeight.w800,
                          color: CaptainColors.primary,
                        ),
                        children: [
                          TextSpan(text: '${trip.boardedCount} '),
                          TextSpan(
                            text: 'صعدوا',
                            style: CaptainTypography.bodySmall(context)
                                .copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: CaptainColors.textSecondaryFor(
                                    context,
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: CaptainDesignTokens.s12),
                ClipRRect(
                  borderRadius: CaptainDesignTokens.br8,
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: CaptainColors.primary.withValues(
                      alpha: 0.1,
                    ),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress == 1.0
                          ? CaptainColors.success
                          : CaptainColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: CaptainDesignTokens.s32),

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
                    const SizedBox(width: CaptainDesignTokens.s12),
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
      AssignedTripStatus.scheduled => (
        'مجدولة',
        CaptainStatusVariant.info,
        Icons.event_rounded,
      ),
      AssignedTripStatus.boarding => (
        'صعود',
        CaptainStatusVariant.warning,
        Icons.people_rounded,
      ),
      AssignedTripStatus.inProgress => (
        'جارية',
        CaptainStatusVariant.success,
        Icons.electric_car_rounded,
      ),
      AssignedTripStatus.completed => (
        'مكتملة',
        CaptainStatusVariant.neutral,
        Icons.check_circle_rounded,
      ),
    };

    return CaptainStatusChip(label: label, variant: variant, icon: icon);
  }
}

class _IconDetail extends StatelessWidget {
  const _IconDetail({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: CaptainColors.textSecondaryFor(context)),
        const SizedBox(width: 6),
        Text(
          text,
          style: CaptainTypography.labelLarge(context).copyWith(
            color: CaptainColors.textSecondaryFor(context),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
