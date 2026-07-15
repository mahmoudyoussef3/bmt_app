import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/l10n/app_localizations.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_booking_status_style.dart';

/// The facts a rider weighs before committing: how long the ride takes and how
/// many seats are still open.
///
/// A panel of fixed cells rather than loose chips — the two numbers land in the
/// same place on every card, so a rider scanning the feed compares departures
/// down a column instead of re-reading each card.
class HomeTripFacts extends StatelessWidget {
  const HomeTripFacts({super.key, required this.trip});

  final UpcomingTripData trip;

  @override
  Widget build(BuildContext context) {
    final border = ClientColors.borderFor(context);
    final l10n = context.l10n;

    return Container(
      decoration: BoxDecoration(
        color: ClientColors.surfaceSubtleFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.sm),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _Fact(
                    icon: Icons.schedule_rounded,
                    caption: l10n.home_rideTime,
                    value: trip.duration.isEmpty
                        ? l10n.common_notSet
                        : trip.duration,
                    color: ClientColors.textPrimaryFor(context),
                  ),
                ),
                VerticalDivider(width: 1, thickness: 1, color: border),
                Expanded(
                  child: _Fact(
                    icon: Icons.event_seat_rounded,
                    caption: l10n.common_seats,
                    value: _seatLabel(trip, l10n),
                    color: _seatColor(trip),
                  ),
                ),
              ],
            ),
          ),
          if (trip.isBooked) ...[
            Divider(height: 1, thickness: 1, color: border),
            _BookedNote(trip: trip),
          ],
        ],
      ),
    );
  }
}

/// One cell: what it is, then the number. Caption above value so the eye lands
/// on the value it came for.
class _Fact extends StatelessWidget {
  const _Fact({
    required this.icon,
    required this.caption,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String caption;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ClientSpacing.sm,
        vertical: 10,
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  caption.toUpperCase(),
                  style: ClientTypography.labelSmall(context).copyWith(
                    color: ClientColors.textTertiaryFor(context),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    height: 1.2,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ClientTypography.labelLarge(
                    context,
                  ).copyWith(color: color, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// What the rider already holds here, so a second booking is a deliberate act
/// rather than an accidental duplicate. The status itself is on the header
/// badge, so this only counts the seats.
class _BookedNote extends StatelessWidget {
  const _BookedNote({required this.trip});

  final UpcomingTripData trip;

  @override
  Widget build(BuildContext context) {
    final accent = trip.bookedStatus!.accent;
    final seats = trip.bookedSeats;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ClientSpacing.sm,
        vertical: 8,
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, size: 15, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              seats > 1
                  ? context.l10n.home_youBookedSeats(seats)
                  : context.l10n.home_youBookedThis,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ClientTypography.labelMedium(
                context,
              ).copyWith(color: accent, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

Color _seatColor(UpcomingTripData trip) {
  if (trip.isSoldOut) return ClientColors.journeyRed;
  return trip.hasScarceSeats
      ? ClientColors.journeyAmber
      : ClientColors.journeyCyan;
}

String _seatLabel(UpcomingTripData trip, AppLocalizations l10n) {
  if (trip.isSoldOut) return l10n.common_soldOut;
  if (trip.hasScarceSeats) return l10n.home_seatsOnlyLeft(trip.seatsLeft);
  return l10n.home_seatsAvailable(trip.seatsLeft);
}
