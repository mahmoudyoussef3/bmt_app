import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/utils/captain_formats.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_button.dart';

import '../../domain/entities/assigned_trip.dart';
import 'assigned_trip_card_parts.dart';

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
    final isDone = trip.status == AssignedTripStatus.completed;

    return Container(
      padding: const EdgeInsets.all(CaptainDesignTokens.s16),
      decoration: BoxDecoration(
        color: CaptainColors.surfaceFor(context),
        borderRadius: CaptainDesignTokens.br24,
        border: Border.all(color: CaptainColors.dividerFor(context)),
        boxShadow: CaptainDesignTokens.softShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  trip.route,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: CaptainTypography.titleSmall(
                    context,
                  ).copyWith(fontWeight: FontWeight.w800, height: 1.3),
                ),
              ),
              const SizedBox(width: CaptainDesignTokens.s8),
              TripStatusBadge(status: trip.status),
            ],
          ),
          const SizedBox(height: CaptainDesignTokens.s12),
          Row(
            children: [
              TripFact(icon: Icons.schedule_rounded, text: _timeRange()),
              const SizedBox(width: CaptainDesignTokens.s12),
              TripFact(
                icon: Icons.directions_bus_rounded,
                text: trip.vehicleNumber.isEmpty
                    ? 'مركبة غير محددة'
                    : trip.vehicleNumber,
              ),
            ],
          ),
          const SizedBox(height: CaptainDesignTokens.s12),
          _BoardingBar(trip: trip),
          const SizedBox(height: CaptainDesignTokens.s16),
          _Actions(
            isDone: isDone,
            isRunning: trip.status.isRunning,
            onOpen: onOpen,
            onManifest: onManifest,
          ),
        ],
      ),
    );
  }

  String _timeRange() =>
      CaptainFormats.timeRange(trip.departureTime, trip.expectedArrivalTime);
}

class _BoardingBar extends StatelessWidget {
  const _BoardingBar({required this.trip});

  final AssignedTrip trip;

  @override
  Widget build(BuildContext context) {
    final progress = trip.passengerCount == 0
        ? 0.0
        : trip.boardedCount / trip.passengerCount;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: CaptainDesignTokens.br8,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: CaptainColors.primary.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1 ? CaptainColors.success : CaptainColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: CaptainDesignTokens.s12),
        Text(
          '${trip.boardedCount}/${trip.passengerCount} صعدوا',
          style: CaptainTypography.labelMedium(context).copyWith(
            color: CaptainColors.textSecondaryFor(context),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.isDone,
    required this.isRunning,
    required this.onOpen,
    required this.onManifest,
  });

  final bool isDone;
  final bool isRunning;
  final VoidCallback onOpen;
  final VoidCallback onManifest;

  @override
  Widget build(BuildContext context) {
    // A completed trip has nothing left to drive — only its manifest is useful.
    if (isDone) {
      return CaptainButton(
        label: 'كشف الركاب',
        icon: Icons.group_rounded,
        onPressed: onManifest,
        variant: CaptainButtonVariant.outline,
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: CaptainButton(
            label: isRunning ? 'متابعة' : 'بدء الرحلة',
            icon: isRunning
                ? Icons.play_arrow_rounded
                : Icons.navigation_rounded,
            onPressed: onOpen,
          ),
        ),
        const SizedBox(width: CaptainDesignTokens.s12),
        Expanded(
          child: CaptainButton(
            label: 'الركاب',
            icon: Icons.group_rounded,
            onPressed: onManifest,
            variant: CaptainButtonVariant.outline,
          ),
        ),
      ],
    );
  }
}
