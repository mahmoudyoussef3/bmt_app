import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_status_badge.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';

class TripCard extends StatelessWidget {
  const TripCard({super.key, required this.trip, required this.onTap});

  final TripData trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ClientColors.surfaceFor(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: ClientColors.borderFor(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status + fare row
            Row(
              children: [
                ClientStatusBadge(
                  status: _journeyStatus(trip.status),
                  label: trip.statusLabel,
                  showDot: trip.status == TripStatus.inProgress,
                ),
                const Spacer(),
                Text(
                  trip.fare,
                  style: ClientTypography.priceSmall(
                    context,
                  ).copyWith(color: ClientColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Route timeline
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: ClientColors.journeyGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 22,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      color: ClientColors.border,
                    ),
                    const Icon(
                      Icons.location_on_rounded,
                      size: 14,
                      color: ClientColors.journeyRed,
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.pickup,
                        style: ClientTypography.bodyMedium(
                          context,
                        ).copyWith(color: ClientColors.textPrimaryFor(context)),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        trip.destination,
                        style: ClientTypography.bodyMedium(
                          context,
                        ).copyWith(color: ClientColors.textPrimaryFor(context)),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: ClientColors.textTertiaryFor(context),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(height: 1, color: ClientColors.borderFor(context)),
            const SizedBox(height: 12),
            // Date + time
            Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 14,
                  color: ClientColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  '${trip.dateLabel} · ${trip.timeLabel}',
                  style: ClientTypography.bodySmall(
                    context,
                  ).copyWith(color: ClientColors.textSecondaryFor(context)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Driver row
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: ClientColors.primaryLight,
                  child: Text(
                    trip.driverInitials,
                    style: ClientTypography.labelSmall(
                      context,
                    ).copyWith(color: ClientColors.primary),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    trip.driverName,
                    style: ClientTypography.bodySmall(
                      context,
                    ).copyWith(color: ClientColors.textSecondaryFor(context)),
                  ),
                ),
                _PaymentChip(
                  label: trip.paymentLabel,
                  status: trip.paymentStatus,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static ClientJourneyStatus _journeyStatus(TripStatus status) {
    return switch (status) {
      TripStatus.upcoming => ClientJourneyStatus.upcoming,
      TripStatus.inProgress => ClientJourneyStatus.active,
      TripStatus.completed => ClientJourneyStatus.completed,
      TripStatus.cancelled => ClientJourneyStatus.cancelled,
    };
  }
}

class _PaymentChip extends StatelessWidget {
  const _PaymentChip({required this.label, required this.status});

  final String label;
  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      PaymentStatus.paid => (
        ClientColors.journeyGreenLight,
        ClientColors.onJourneyGreen,
      ),
      PaymentStatus.pending => (
        ClientColors.journeyAmberLight,
        ClientColors.onJourneyAmber,
      ),
      PaymentStatus.underReview => (
        ClientColors.journeyAmberLight,
        ClientColors.onJourneyAmber,
      ),
      PaymentStatus.failed => (
        ClientColors.journeyRedLight,
        ClientColors.onJourneyRed,
      ),
      PaymentStatus.refunded => (
        ClientColors.journeySlateLight,
        ClientColors.onJourneySlate,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: ClientTypography.labelSmall(context).copyWith(color: fg),
      ),
    );
  }
}
