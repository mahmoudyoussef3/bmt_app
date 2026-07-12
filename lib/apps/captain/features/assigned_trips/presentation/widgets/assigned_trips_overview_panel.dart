import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

import 'assigned_trips_metric.dart';

/// Day-at-a-glance for the captain: trip counts plus boarding progress.
class AssignedTripsOverviewPanel extends StatelessWidget {
  const AssignedTripsOverviewPanel({
    super.key,
    required this.trips,
    required this.passengers,
    required this.boarded,
    required this.activeTrips,
  });

  final int trips;
  final int passengers;
  final int boarded;
  final int activeTrips;

  @override
  Widget build(BuildContext context) {
    final progress = passengers == 0 ? 0.0 : boarded / passengers;

    return Container(
      decoration: BoxDecoration(
        color: CaptainColors.surfaceFor(context),
        borderRadius: CaptainDesignTokens.br24,
        boxShadow: CaptainDesignTokens.floatingShadow(context),
        border: Border.all(color: CaptainColors.primary.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.all(CaptainDesignTokens.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AssignedTripsMetric(
                label: 'الرحلات',
                value: trips.toString(),
                icon: Icons.route_rounded,
                color: CaptainColors.primary,
              ),
              const SizedBox(width: CaptainDesignTokens.s12),
              AssignedTripsMetric(
                label: 'نشطة',
                value: activeTrips.toString(),
                icon: Icons.bolt_rounded,
                color: Colors.orange,
                isHighlight: activeTrips > 0,
              ),
              const SizedBox(width: CaptainDesignTokens.s12),
              AssignedTripsMetric(
                label: 'الركاب',
                value: passengers.toString(),
                icon: Icons.people_alt_rounded,
                color: Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: CaptainDesignTokens.s24),
          _BoardingProgress(
            progress: progress,
            boarded: boarded,
            passengers: passengers,
          ),
        ],
      ),
    );
  }
}

class _BoardingProgress extends StatelessWidget {
  const _BoardingProgress({
    required this.progress,
    required this.boarded,
    required this.passengers,
  });

  final double progress;
  final int boarded;
  final int passengers;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(CaptainDesignTokens.s16),
      decoration: BoxDecoration(
        color: CaptainColors.primary.withValues(alpha: 0.03),
        borderRadius: CaptainDesignTokens.br16,
        border: Border.all(color: CaptainColors.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'تقدم الصعود',
                style: CaptainTypography.labelLarge(context).copyWith(
                  color: CaptainColors.textPrimaryFor(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: CaptainColors.primary.withValues(alpha: 0.1),
                  borderRadius: CaptainDesignTokens.br8,
                ),
                child: Text(
                  '${(progress * 100).round()}%',
                  style: CaptainTypography.titleSmall(context).copyWith(
                    color: CaptainColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: CaptainDesignTokens.s16),
          ClipRRect(
            borderRadius: CaptainDesignTokens.br8,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: CaptainColors.primary.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(
                CaptainColors.primary,
              ),
            ),
          ),
          const SizedBox(height: CaptainDesignTokens.s12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: CaptainColors.textSecondaryFor(context),
              ),
              const SizedBox(width: CaptainDesignTokens.s8),
              Text(
                'صعد $boarded من أصل $passengers راكب',
                style: CaptainTypography.labelMedium(context).copyWith(
                  color: CaptainColors.textSecondaryFor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
