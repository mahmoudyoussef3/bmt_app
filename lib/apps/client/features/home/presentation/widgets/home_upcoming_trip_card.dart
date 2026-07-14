import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/apps/client/core/utils/trip_schedule_format.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_booking_status_style.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_trip_actions.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_trip_journey.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/pulse_dot.dart';

/// One bookable departure, full width: when it leaves, which route it runs,
/// where it stops, what is left on it and what it costs.
class HomeUpcomingTripCard extends StatelessWidget {
  const HomeUpcomingTripCard({
    super.key,
    required this.trip,
    required this.onBook,
  });

  final UpcomingTripData trip;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    // A departure the rider already holds a seat on is outlined in its booking
    // status colour, so they spot it in the feed before they read a word.
    final borderColor = trip.isBooked
        ? trip.bookedStatus!.accent.withAlpha(80)
        : ClientColors.borderFor(context);

    return PressableScale(
      onTap: trip.isSoldOut ? null : onBook,
      scale: 0.99,
      child: Container(
        padding: const EdgeInsets.all(ClientSpacing.md),
        decoration: BoxDecoration(
          color: ClientColors.surfaceFor(context),
          borderRadius: BorderRadius.circular(ClientRadius.lg),
          border: Border.all(color: borderColor),
          boxShadow: ClientElevation.sm(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ScheduleRow(trip: trip),
            const SizedBox(height: ClientSpacing.md),
            HomeTripJourney(
              pickup: trip.pickup,
              destination: trip.destination,
            ),
            const SizedBox(height: ClientSpacing.md),
            HomeTripMetrics(trip: trip),
            const SizedBox(height: ClientSpacing.md),
            Divider(height: 1, color: ClientColors.borderFor(context)),
            const SizedBox(height: ClientSpacing.md),
            HomeTripCta(trip: trip, onBook: onBook),
          ],
        ),
      ),
    );
  }
}

/// Departure time is the headline — it is what a rider scans for — with the
/// route name underneath for context and a live badge when boarding is open.
class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.trip});

  final UpcomingTripData trip;

  @override
  Widget build(BuildContext context) {
    final time = formatTripTime(context, trip.departureTime);
    final day = formatTripDay(context, trip.tripDate);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      time.isEmpty ? 'Departure time to be set' : time,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ClientTypography.headingMedium(
                        context,
                      ).copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (day.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      '· $day',
                      style: ClientTypography.labelMedium(context).copyWith(
                        color: ClientColors.textSecondaryFor(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                trip.routeName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.bodySmall(
                  context,
                ).copyWith(color: ClientColors.textSecondaryFor(context)),
              ),
            ],
          ),
        ),
        // The rider's own stake in this departure outranks how it is running:
        // "Under review" is what they came to the app to check.
        if (trip.isBooked)
          ClientStatusBadge(
            status: trip.bookedStatus!.badge,
            label: trip.bookedStatus!.label,
            showDot: trip.bookedStatus!.isPulsing,
          )
        else if (trip.isLive)
          const _BoardingBadge(),
      ],
    );
  }
}

class _BoardingBadge extends StatelessWidget {
  const _BoardingBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ClientColors.journeyGreen.withAlpha(20),
        borderRadius: BorderRadius.circular(ClientRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PulseDot(color: ClientColors.journeyGreen, size: 7),
          const SizedBox(width: 6),
          Text(
            'Boarding',
            style: ClientTypography.labelSmall(context).copyWith(
              color: ClientColors.journeyGreen,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
