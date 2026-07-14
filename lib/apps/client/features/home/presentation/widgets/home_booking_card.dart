import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/utils/trip_schedule_format.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_booking_status_note.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_booking_status_style.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_trip_chip.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_trip_journey.dart';

/// A seat the rider already holds, with where it stands. The status is the
/// headline: a rider who has just paid needs to see that the booking exists and
/// that it is being reviewed — not silence.
class HomeBookingCard extends StatelessWidget {
  const HomeBookingCard({
    super.key,
    required this.booking,
    required this.onTrack,
  });

  final HomeBookingData booking;

  /// Opens live tracking. Only offered once the seat is confirmed — there is
  /// no bus to follow while payment is still under review.
  final ValueChanged<HomeBookingData> onTrack;

  @override
  Widget build(BuildContext context) {
    final status = booking.status;
    final trackable = status.isTrackable;

    return ClientCard(
      onTap: trackable ? () => onTrack(booking) : null,
      padding: const EdgeInsets.all(ClientSpacing.lg),
      borderColor: status.accent.withAlpha(70),
      useShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(booking: booking),
          const SizedBox(height: ClientSpacing.md),
          HomeTripJourney(
            pickup: booking.pickup,
            destination: booking.destination,
          ),
          const SizedBox(height: ClientSpacing.md),
          _Facts(booking: booking),
          const SizedBox(height: ClientSpacing.md),
          HomeBookingStatusNote(status: status),
          if (trackable) ...[
            const SizedBox(height: ClientSpacing.md),
            ClientButton(
              label: 'Track your bus',
              icon: const Icon(
                Icons.near_me_rounded,
                color: Colors.white,
                size: 19,
              ),
              onPressed: () => onTrack(booking),
            ),
          ],
        ],
      ),
    );
  }
}

/// Booking reference on the left, status badge on the right — the two things a
/// rider looks for when they open the app after paying.
class _Header extends StatelessWidget {
  const _Header({required this.booking});

  final HomeBookingData booking;

  @override
  Widget build(BuildContext context) {
    final reference = booking.bookingNumber.isEmpty
        ? 'Your booking'
        : booking.bookingNumber;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reference,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.labelLarge(
                  context,
                ).copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(
                _schedule(context, booking),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.bodySmall(
                  context,
                ).copyWith(color: ClientColors.textSecondaryFor(context)),
              ),
            ],
          ),
        ),
        const SizedBox(width: ClientSpacing.sm),
        ClientStatusBadge(
          status: booking.status.badge,
          label: booking.status.label,
          showDot: booking.status.isPulsing,
        ),
      ],
    );
  }
}

/// Seat and what was paid — the receipt facts, as chips.
class _Facts extends StatelessWidget {
  const _Facts({required this.booking});

  final HomeBookingData booking;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: ClientSpacing.xs,
      runSpacing: ClientSpacing.xs,
      children: [
        if (booking.seatLabel.isNotEmpty)
          HomeTripChip(
            color: ClientColors.journeySlate,
            icon: Icons.event_seat_rounded,
            label: 'Seat ${booking.seatLabel}',
          ),
        if (booking.fare.isNotEmpty)
          HomeTripChip(
            color: booking.status.accent,
            icon: Icons.payments_rounded,
            label: booking.fare,
          ),
      ],
    );
  }
}

String _schedule(BuildContext context, HomeBookingData booking) {
  final day = formatTripDay(context, booking.tripDate);
  final time = formatTripTime(context, booking.departureTime);
  final parts = [day, time].where((part) => part.isNotEmpty);
  return parts.isEmpty ? booking.routeLabel : parts.join(' · ');
}
