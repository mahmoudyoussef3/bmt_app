import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_booking_status_style.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_trip_chip.dart';

/// The facts a rider weighs before committing: how long the ride takes and
/// how many seats are still open.
class HomeTripMetrics extends StatelessWidget {
  const HomeTripMetrics({super.key, required this.trip});

  final UpcomingTripData trip;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: ClientSpacing.xs,
      runSpacing: ClientSpacing.xs,
      children: [
        if (trip.duration.isNotEmpty)
          HomeTripChip(
            color: ClientColors.journeySlate,
            icon: Icons.schedule_rounded,
            label: trip.duration,
          ),
        HomeTripChip(
          color: _seatColor(trip),
          icon: Icons.event_seat_rounded,
          label: _seatLabel(trip),
        ),
        if (trip.isBooked)
          HomeTripChip(
            color: trip.bookedStatus!.accent,
            icon: Icons.check_circle_rounded,
            label: _bookedLabel(trip),
          ),
      ],
    );
  }
}

/// What the rider already holds here, so a second booking is a deliberate act
/// rather than an accidental duplicate. The status itself is on the card's
/// badge, so this only counts the seats.
String _bookedLabel(UpcomingTripData trip) {
  final seats = trip.bookedSeats;
  return seats > 1 ? 'You booked $seats seats' : 'You booked this';
}

Color _seatColor(UpcomingTripData trip) {
  if (trip.isSoldOut) return ClientColors.journeyRed;
  return trip.hasScarceSeats
      ? ClientColors.journeyAmber
      : ClientColors.journeyGreen;
}

String _seatLabel(UpcomingTripData trip) {
  if (trip.isSoldOut) return 'Sold out';
  if (trip.hasScarceSeats) return 'Only ${trip.seatsLeft} seats left';
  return '${trip.seatsLeft} seats left';
}

/// Fare on the left, the single call to action on the right.
///
/// A trip the rider has already booked stays bookable — booking a second seat
/// for a friend is a real thing riders do — but the button says so, so nobody
/// double-books by mistake.
class HomeTripCta extends StatelessWidget {
  const HomeTripCta({super.key, required this.trip, required this.onBook});

  final UpcomingTripData trip;
  final VoidCallback onBook;

  String get _label {
    if (trip.isSoldOut) return 'Sold out';
    return trip.isBooked ? 'Book another seat' : 'Book seat';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _Fare(price: trip.price)),
        const SizedBox(width: ClientSpacing.sm),
        FilledButton(
          onPressed: trip.isSoldOut ? null : onBook,
          style: FilledButton.styleFrom(
            backgroundColor: trip.isBooked
                ? ClientColors.surfaceMutedFor(context)
                : ClientColors.primaryFor(context),
            foregroundColor: trip.isBooked
                ? ClientColors.primaryFor(context)
                : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ClientRadius.sm),
              side: trip.isBooked
                  ? BorderSide(color: ClientColors.primaryFor(context))
                  : BorderSide.none,
            ),
          ),
          child: Text(
            _label,
            style: ClientTypography.labelMedium(context).copyWith(
              color: trip.isBooked
                  ? ClientColors.primaryFor(context)
                  : Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _Fare extends StatelessWidget {
  const _Fare({required this.price});

  final String price;

  @override
  Widget build(BuildContext context) {
    if (price.isEmpty) {
      return Text(
        'Fare not published yet',
        style: ClientTypography.bodySmall(
          context,
        ).copyWith(color: ClientColors.textTertiaryFor(context)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fare from',
          style: ClientTypography.labelSmall(
            context,
          ).copyWith(color: ClientColors.textTertiaryFor(context)),
        ),
        Text(
          price,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ClientTypography.priceMedium(
            context,
          ).copyWith(color: ClientColors.primaryFor(context)),
        ),
      ],
    );
  }
}
