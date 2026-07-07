import 'package:flutter/material.dart';

import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

class TripCard extends StatelessWidget {
  const TripCard({super.key, required this.trip, required this.onTap});

  final TripData trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusChip(
                label: trip.statusLabel,
                color: _journeyStatusColor(trip.status, scheme),
                textColor: _journeyStatusColor(trip.status, scheme),
              ),
              const Spacer(),
              Text(
                trip.fare,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RouteMarks(
                pickupColor: scheme.tertiary,
                dropoffColor: scheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.pickup,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      trip.destination,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: scheme.outline),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: scheme.outline.withAlpha(90)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 14, color: scheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${trip.dateLabel} · ${trip.timeLabel}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withAlpha(170),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: scheme.primary.withAlpha(18),
                child: Text(
                  trip.driverInitials,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  trip.driverName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
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
    );
  }

  static Color _journeyStatusColor(TripStatus status, ColorScheme scheme) {
    return switch (status) {
      TripStatus.upcoming => scheme.primary,
      TripStatus.inProgress => scheme.tertiary,
      TripStatus.completed => scheme.secondary,
      TripStatus.cancelled => scheme.error,
    };
  }
}

class _RouteMarks extends StatelessWidget {
  const _RouteMarks({required this.pickupColor, required this.dropoffColor});

  final Color pickupColor;
  final Color dropoffColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: pickupColor, shape: BoxShape.circle),
        ),
        Container(
          width: 2,
          height: 22,
          margin: const EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(
            color: pickupColor.withAlpha(90),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        Icon(Icons.location_on_rounded, size: 14, color: dropoffColor),
      ],
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
